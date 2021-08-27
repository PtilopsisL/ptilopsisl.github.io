# POSIX标准
POSIX标准的诞生是为了阻止Unix各类系统朝着互相不兼容的趋势发展。这套标准涵盖了很多方面，比如Unix系统调用的C语言接口、shell程序和工具、线程及网络编程。

POSIX标准的详细内容可点击链接查看<https://pubs.opengroup.org/onlinepubs/9699919799/>

### 支持POSIX的系统(部分)
#### 完全支持
- Solaris
- macOS (since 10.5 Leopard)
#### 大多支持
- Android
- Darwin
- FreeBSD
- Linux
- MINIX
#### 用于Windows的POSIX
Windows对POSIX的支持并不是很好，需要一些额外的软件为Windows提供POSIX环境的支持。
- Cygwin
- MinGW

### POSIX标准的部分特点
- 定义接口，但不定义实现。一般来说大部分的标准也只会给你定义有哪些接口，实现部分则是各自用各自的方法去完成。
- POSIX中对系统接口和头文件的定义是按照ISO C标准中规定的标准C语言来编写的。
- 最少的接口与定义。POSIX中强制性的核心设施保持在尽可能少的程度，额外的功能被添加为可选的拓展。

POSIX的定义包含以下四大部分：
- 基础定义`Base Definitions`
- 系统接口`System Interfaces`
- 终端与实用工具`Shell and Utilities`
- 理论依据`Rationale (Informative)`

### 基础定义`Base Definitions`
- 重要的系统概念的定义
如进程(Process)、线程(Thread)、管道(Pipe)、套接字(Socket)等等
- 一般概念`General Concepts`
一些细节如文件名应该对大小写敏感、文件的访问权限(read, write, execute)等等。
- 字符编码
- 环境变量
包含平时常见的`CC`、`HOME`、`PATH`、`PWD`、`SHELL`等环境变量。
- 正则表达式
- 头文件
定义了包括`<stdio.h>`、`<stdlib.h>`、`<string.h>`、`<pthread.h>`等诸多头文件中需要包含的内容。

### 系统接口`System Interfaces`
- 错误代码
- 信号
- 进程调度策略
- 包含`mmap`、`write`、`socket`、`open`等系统接口。
  
### 终端与实用工具`Shell and Utilities`
- Shell命令语言
包含语言细节、保留关键字、重定向、语法、内建命令(如`export`,`exec`,`unset`)等。
- 批处理作业环境
- 实用工具
包含`vi`、`cd`、`chmod`、`echo`等常用工具。

### 理论依据`Rationale (Informative)`
- 主要会讲述定义某些东西背后的原因
- 分为五个章节，分别讲述基础定义、系统接口、终端与实用工具、可移植性和`Subprofiling Considerations`