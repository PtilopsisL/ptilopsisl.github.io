# 编译一个交叉编译器(cross compiler)
教程参考<https://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/>
## 前言
- 这里尝试的是在`Linux`系统中编译一个生成`Linux`可执行文件的交叉编译器，未尝试过编译`target`为`mingw32`或`cygwin`的交叉编译器。
- 如果只想让编译器编译出汇编代码，不需要执行完所有的步骤。以下两种方法均能实现从源文件生成汇编代码，但你的源文件中不能使用标准库中的函数，如`printf`等，或者可以自行安装标准库包含的头文件。
  - 使用`clang`。可以直接安装`clang`来生成汇编代码，生成方式如`clang -S -target riscv64 test.c -o test.s`。这里通过指定`-target`的方式来生成相应的汇编代码，只需要把`-target`指定的内容换成其他名称如`aarch64 riscv32`等就能编译出相应指令集的汇编代码。
  - 执行完`gcc`的第一次编译安装，即执行完`make install-gcc`后就结束。生成汇编的方式：`riscv64-pc-linux-gcc -S test.c -o test.s`。这里`gcc`前面的`riscv64-pc-linux`是你指定的`-target`。
- 最好不要在WSL环境中进行编译。因为某一些原因，最后在执行`glibc`的第二遍编译的时候会出错。使用其他虚拟机能避免这个问题。
- 交叉编译过程未在`Cygwin`、`MinGW`中测试过，可行性未知。
## 源代码、依赖库下载/安装
### 源代码
这次编译需要的源代码有：

- `binutils`
- `gcc`
- `glibc`
- `linux`

以上内容均可以从镜像源中获取，获取方式：
```bash
wget https://mirrors.ustc.edu.cn/gnu/binutils/binutils-2.37.tar.gz
wget https://mirrors.ustc.edu.cn/gnu/gcc/gcc-9.4.0/gcc-9.4.0.tar.gz
wget https://mirrors.ustc.edu.cn/gnu/glibc/glibc-2.31.tar.gz
git clone https://mirrors.ustc.edu.cn/linux.git
```

- 这里`glibc`为了兼容性建议选`2.31`版本，当然如果你不打算把用交叉编译器编译出的程序放到别的机器上运行，则可以不用考虑兼容性，或者在用交叉编译器编译的时候指定`-static`选项。
- `Linux`源代码在本次编译中只用于安装头文件，如果认为`clone`整个代码库占用空间太大，可以下载源代码`tarball`。
- `gcc`9版本与10版本都经过测试能成功编译，其他版本未测试过可行性。
### 依赖库(不需要源代码)
需要的依赖库有：

- `gmp`
- `mpfr`
- `mpc`

在本次编译过程中不需要以上依赖库的源代码，因此可以自己从源代码安装或直接使用包管理器安装。在以`apt`为包管理器的系统上可执行：
```bash
sudo apt install libgmp-dev libmpfr-dev libmpc-dev
```

## 需预先了解的知识
### `build`、`host`与`target`
一般在编译库的时候只有`build`和`target`两个选项，在编译编译器的时候则有以上三个选项。这三个选项的意义是：在`build`机器上编译出能在`host`机器上运行，生成`target`机器代码的编译器。
### `cpu-company-system`格式
指定`host`或`target`需要按照上述格式来指定，当然其中最重要的还是`cpu`和`system`两个部分，`company`似乎是可以随便写的。

- `cpu`：填写指令集名称，如`aarch64`、`riscv32`、`mips64`等。
- `company`：可以用`gcc -v`看一看自己编译器中的`company`是什么（一般来说是`pc`）然后填上去，或者直接指定为`unknown`。
- `system`：这里填写的内容主要决定的是程序的运行格式，`Linux`系统的可执行文件格式是`elf`，这里填写`linux`、`gnu`或`elf`都是差不多的。

`gcc`支持的所有`cpu`与`system`类型可以查看<https://gcc.gnu.org/install/configure.html>。
## 编译过程
这里会详细介绍一下编译过程，最后会给出一个完整的脚本。
### 1.设置变量
```bash
WORKING_DIR=$PWD

LINUX_ARCH=riscv
TARGET=riscv64-pc-linux
PREFIX=$PWD/usr
TARGET_PREFIX=$PREFIX/$TARGET
export PATH=$PATH:$PREFIX/bin
PARALLEL_MAKE=-j8
CONFIGURATION_OPTIONS="--disable-multilib --disable-threads"

BINUTILS=binutils-2.37
GCC=gcc-10.3.0
GLIBC=glibc-2.34
LINUX=linux-stable
```
说明：

- `LINUX_ARCH`是目标机器指令集名称，该名称需要查看`Linux`源代码中的`arch`文件夹，找到相对应的名称。比如说`aarch64`不能直接填`aarch64`，应当填写`arm64`。
- `TARGET`即为先前介绍过的`cpu-company-system`格式。
- `PREFIX`为安装文件夹。
- 如果编译环境的内存不是很充足，建议将`PARALLEL_MAKE`的并行数改小一点。
- `CONFIGURATION_OPTIONS`中的`--disable-multilib --disable-threads`最好加上，否则可能会出现问题。如果想让编译器加上编译多线程程序的功能，可以执行完一次完整编译之后再进行。
### 2.编译binutils
这一步编译出的是`as`、`ld`等工具，在本机上可以运行的处理`target`机器代码的工具。
```bash
cd $BINUTILS
mkdir build
cd build
../configure --prefix=$PREFIX --target=$TARGET $CONFIGURATION_OPTIONS
make ${PARALLEL_MAKE}
make install
```
### 3.安装linux-headers
这一步安装的是`Linux`头文件，不需要编译内核源代码。
```bash
cd $WORKING_DIR
cd $LINUX
make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=$TARGET_PREFIX headers_install
```
### 4.C/C++编译器(gcc第一遍编译)
第一遍编译的内容只包含编译器，不包含相关的依赖等。
```bash
cd $WORKING_DIR
cd $GCC
rm -rf build
mkdir build
cd build
../configure --target=$TARGET --prefix=$PREFIX $CONFIGURATION_OPTIONS --enable-languages=c,c++
make ${PARALLEL_MAKE} all-gcc
make install-gcc
```
### 5.C库头文件与Startup Files(glibc第一遍)
这一步是安装头文件再加上Startup Files，这些是编译器进行编译的必要条件。
```bash
cd $WORKING_DIR
cd $GLIBC
rm -rf build
mkdir build
cd build
../configure --host=$TARGET --target=$TARGET --prefix=$PREFIX/$TARGET --with-headers=$TARGET_PREFIX/include $CONFIGURATION_OPTIONS CC=${TARGET}-gcc
make install-headers
make $PARALLEL_MAKE csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/$TARGET/lib/libc.so
```
### 6.编译gcc库(gcc第二遍编译)
这一步会编译出`libgcc`，这个库会在后续完整编译`glibc`时会用到。
```bash
cd $WORKING_DIR
cd $GCC
cd build
make $PARALLEL_MAKE all-target-libgcc
make install-target-libgcc
```
### 7.标准C库(glibc第二遍)
这一步会完整编译出C基础库。
```bash
cd $WORKING_DIR
cd $GLIBC
cd build
make $PARALLEL_MAKE
make install
```
### 8.标准C++库
在编译之前需要修改源代码中的`libsanitizer/asan/asan_linux.cc`（`gcc-9`与`gcc-10`都需要修改这个部分，或许其他版本也要加），在开头位置加入：
```C
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif
```
修改完之后可以开始编译：
```bash
cd $WORKING_DIR
cd $GCC
cd build
make $PARALLEL_MAKE all
make install
```
### 完整脚本
经测试，这个脚本可以成功执行整个编译的过程。但还是建议按照上述步骤一步一步执行，避免中途出现一些问题。

执行前需要先按照先前的说明，对环境变量进行一些修改。
```bash
#!/bin/bash
export WORKING_DIR=$PWD

export LINUX_ARCH=riscv
export TARGET=riscv64-pc-linux
export PREFIX=$PWD/usr
export TARGET_PREFIX=$PREFIX/$TARGET
export PATH=$PATH:$PREFIX/bin
export PARALLEL_MAKE=-j8
export CONFIGURATION_OPTIONS="--disable-multilib --disable-threads"

export BINUTILS=binutils-2.37
export GCC=gcc-10.3.0
export GLIBC=glibc-2.34
export LINUX=linux-stable

echo -e "\e[1;31mUnpack tarball? (y/n)\e[0m"
read input
if [ $input = y ] || [ $input = Y ]; then
	tar -xvf ${BINUTILS}.tar.gz
	tar -xvf ${GCC}.tar.gz
	tar -xvf ${GLIBC}.tar.gz
	echo -e "\e[1;31mFinish unpack.\e[0m"
fi

cd $BINUTILS
rm -rf build
mkdir build
cd build
../configure --prefix=$PREFIX --target=$TARGET $CONFIGURATION_OPTIONS
make ${PARALLEL_MAKE}
make install

cd $WORKING_DIR
cd $LINUX
make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=$TARGET_PREFIX headers_install

cd $WORKING_DIR
cd $GCC
rm -rf build
mkdir build
cd build
../configure --target=$TARGET --prefix=$PREFIX $CONFIGURATION_OPTIONS --enable-languages=c,c++
make ${PARALLEL_MAKE} all-gcc
make install-gcc

cd $WORKING_DIR
cd $GLIBC
rm -rf build
mkdir build
cd build
../configure --host=$TARGET --target=$TARGET --prefix=$PREFIX/$TARGET --with-headers=$TARGET_PREFIX/include $CONFIGURATION_OPTIONS CC=${TARGET}-gcc
make install-headers
make $PARALLEL_MAKE csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/$TARGET/lib/libc.so

cd $WORKING_DIR
cd $GCC
cd build
make $PARALLEL_MAKE all-target-libgcc
make install-target-libgcc

cd $WORKING_DIR
cd $GLIBC
cd build
make $PARALLEL_MAKE
make install

cd $WORKING_DIR
cd $GCC
cd build
make $PARALLEL_MAKE all
make install

cd $WORKING_DIR
echo -e "\e[1;31mSuccess\e[0m"
```
## 结果
执行完一次`target`为`riscv64`的交叉编译器的编译，使用它编译一个输出`Hello world!`的C文件，执行反汇编后输出如下的结果：
```
$ llvm-objdump -d hello
hello:	file format ELF64-riscv


Disassembly of section .plt:

00000000000103f0 _PROCEDURE_LINKAGE_TABLE_:
   103f0: 97 23 00 00 33 03 c3 41         .#..3..A
   103f8: 03 be 03 c1 13 03 43 fd         ......C.
   10400: 93 82 03 c1 13 53 13 00         .....S..
   10408: 83 b2 82 00 67 00 0e 00         ....g...
   10410: 17 2e 00 00 03 3e 0e c0         .....>..
   10418: 67 03 0e 00 13 00 00 00         g.......
   10420: 17 2e 00 00 03 3e 8e bf         .....>..
   10428: 67 03 0e 00 13 00 00 00         g.......

Disassembly of section .text:

0000000000010430 _start:
   10430: ef 00 20 02                  	jal	34
   10434: aa 87                        	add	a5, zero, a0
   10436: 17 05 00 00                  	auipc	a0, 0
   1043a: 13 05 e5 08                  	addi	a0, a0, 142
   1043e: 82 65                        	ld	a1, 0(sp)
   10440: 30 00                        	addi	a2, sp, 8
   10442: 13 71 01 ff                  	andi	sp, sp, -16
   10446: 81 46                        	mv	a3, zero
   10448: 01 47                        	mv	a4, zero
   1044a: 0a 88                        	add	a6, zero, sp
   1044c: ef f0 5f fc                  	jal	-60
   10450: 02 90                        	ebreak	

0000000000010452 load_gp:
   10452: 97 21 00 00                  	auipc	gp, 2
   10456: 93 81 e1 3a                  	addi	gp, gp, 942
   1045a: 82 80                        	ret
   1045c: 00 00                        	unimp	

000000000001045e deregister_tm_clones:
   1045e: 49 65                        	lui	a0, 18
   10460: 49 67                        	lui	a4, 18
   10462: 93 07 05 00                  	mv	a5, a0
   10466: 13 07 07 00                  	mv	a4, a4
   1046a: 63 08 f7 00                  	beq	a4, a5, 16
   1046e: 93 07 00 00                  	mv	a5, zero
   10472: 81 c7                        	beqz	a5, 8
   10474: 13 05 05 00                  	mv	a0, a0
   10478: 82 87                        	jr	a5
   1047a: 82 80                        	ret

000000000001047c register_tm_clones:
   1047c: 49 65                        	lui	a0, 18
   1047e: 93 07 05 00                  	mv	a5, a0
   10482: 49 67                        	lui	a4, 18
   10484: 93 05 07 00                  	mv	a1, a4
   10488: 9d 8d                        	sub	a1, a1, a5
   1048a: 93 d7 35 40                  	srai	a5, a1, 3
   1048e: fd 91                        	srli	a1, a1, 63
   10490: be 95                        	add	a1, a1, a5
   10492: 85 85                        	srai	a1, a1, 1
   10494: 99 c5                        	beqz	a1, 14
   10496: 93 07 00 00                  	mv	a5, zero
   1049a: 81 c7                        	beqz	a5, 8
   1049c: 13 05 05 00                  	mv	a0, a0
   104a0: 82 87                        	jr	a5
   104a2: 82 80                        	ret

00000000000104a4 __do_global_dtors_aux:
   104a4: 41 11                        	addi	sp, sp, -16
   104a6: 22 e0                        	sd	s0, 0(sp)
   104a8: 83 c7 81 83                  	lbu	a5, -1992(gp)
   104ac: 06 e4                        	sd	ra, 8(sp)
   104ae: 91 e7                        	bnez	a5, 12
   104b0: ef f0 ff fa                  	jal	-82
   104b4: 85 47                        	addi	a5, zero, 1
   104b6: 23 8c f1 82                  	sb	a5, -1992(gp)
   104ba: a2 60                        	ld	ra, 8(sp)
   104bc: 02 64                        	ld	s0, 0(sp)
   104be: 41 01                        	addi	sp, sp, 16
   104c0: 82 80                        	ret

00000000000104c2 frame_dummy:
   104c2: 6d bf                        	j	-70

00000000000104c4 main:
   104c4: 41 11                        	addi	sp, sp, -16
   104c6: 06 e4                        	sd	ra, 8(sp)
   104c8: 22 e0                        	sd	s0, 0(sp)
   104ca: 00 08                        	addi	s0, sp, 16
   104cc: c1 67                        	lui	a5, 16
   104ce: 13 85 87 4e                  	addi	a0, a5, 1256
   104d2: ef f0 ff f4                  	jal	-178
   104d6: 81 47                        	mv	a5, zero
   104d8: 3e 85                        	add	a0, zero, a5
   104da: a2 60                        	ld	ra, 8(sp)
   104dc: 02 64                        	ld	s0, 0(sp)
   104de: 41 01                        	addi	sp, sp, 16
   104e0: 82 80                        	ret
```
可以看到成功生成了`riscv64`的代码。