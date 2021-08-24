# 编译一个交叉编译器(cross compiler)
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
wget https://mirrors.ustc.edu.cn/gnu/glibc/glibc-2.34.tar.gz
git clone https://mirrors.ustc.edu.cn/linux.git
```
### 依赖库(不需要源代码)
需要的依赖库有：
- `gmp`
- `mpfr`
- `mpc`
在本次编译过程中不需要以上依赖库的源代码，因此可以自己从源代码安装或直接使用包管理器安装。在以`apt`为包管理器的系统上可执行：
```bash
$ sudo apt install libgmp-dev libmpfr-dev libmpc-dev
```
## 坑与建议
- 如果只想让编译器编译出汇编代码，不需要执行完所有的步骤。以下两种方法均能实现从源文件生成汇编代码，但你的源文件中不能使用标准库中的函数，如`printf`等：
  - 使用`clang`。可以直接安装`clang`来生成汇编代码，生成方式如`clang -S -target riscv64 test.c -o test.s`。只需要把`-target`指定的内容换成其他名称如`aarch64 riscv32`等就能编译出相应指令集的汇编代码。
  - 执行完`gcc`的第一次编译安装，即执行完`make install-gcc`后就结束。生成汇编的方式：`riscv64-pc-linux-gcc -S test.c -o test.s`。这里`gcc`前面的`riscv64-pc-linux`是你指定的`-target`。
- 最好不要在WSL环境中进行编译。因为某一些原因，最后在执行`glibc`的第二遍编译的时候会出错。使用其他虚拟机能避免这个问题。
- 交叉编译过程未在`Cygwin`、`MinGW`中测试过，可行性未知。
- 尽量使用`gcc-9.4.0`之前的版本，新版`gcc`在编译过程中可能会出现问题。
- `--disable-multilib --disable-threads`最好加上，否则可能会出现问题。
## 需预先了解的知识
## 编译过程
### 1.设置变量
```bash
INSTALL_PATH=$HOME/usr
TARGET=riscv64-pc-linux
LINUX_ARCH=riscv
CONFIGURATION_OPTIONS="--disable-multilib --disable-threads"
PARALLEL_MAKE=-j8

export PATH=$INSTALL_PATH/bin:$PATH
```
### 2.编译binutils
```bash
cd build-binutils
../configure --prefix=$INSTALL_PATH --target=$TARGET $CONFIGURATION_OPTIONS
make $PARALLEL_MAKE
make install
```
### 3.安装linux-headers
```bash
```
### 4.C/C++编译器(gcc第一遍编译)
第一遍编译的内容不包含运行时等
```bash
```
### 5.C库头文件与Startup Files(glibc第一遍)
```bash
```
### 6.编译gcc库(gcc第二遍编译)
```bash
```
### 7.标准C库(glibc第二遍)
```bash
```
### 8.标准C++库
```bash
```