# `ppdb` – A debugger for proabilistic programs

`ppdb` is a proof-of-concept implementation of a debugger for probabilistic programs.

## Build instructions

### Mac-GUI

Open the Xcode Project in `/GUI/GUI.xcodeproj` and build the `GUI` target.

Open the file to debug using the File -> Open menu.

### Command line interface

```bash
$ cd "Swift Package"
$ swift build
$ .build/debug/ppdb path/to/file/to/debug.sl
> help
```