## JIT

Toolkit should not include JIT compilation.
Creating a performant JIT compilation system would require many thousands of man-hours of engineering, which I do not have. It is better that I do not duplicate efforts by others that are more qualified than I am.

As such, the toolkit shall have an interpreter, which will sufficiently optimized for scripting purposes and fast iteration and so forth. If JIT compilation is required -- it probably isn't, because I am not building a dynamic language -- then the JVM or the CLR could be targeted. Some way of translating the custom bytecode format to the bytecode formats for these platforms could be provided. 