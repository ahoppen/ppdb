# `ppdb` – A debugger for proabilistic programs

`ppdb` is a proof-of-concept implementation of a debugger for probabilistic programs.

## Running pre-built binaries

### macOS

Download the latest version of the debugger's GUI or command line interface from the project's [Releases](https://github.com/ahoppen/ppdb/releases) page and run it.

Sample programs to debug can be found in the [Samples](https://github.com/ahoppen/ppdb/tree/master/Samples) folder

### Linux

1. Install Swift on your machine as described on [swift.org](https://swift.org/getting-started/#installing-swift)
2. Download the latest command line executable from the project's  [Releases](https://github.com/ahoppen/ppdb/releases) page and execute it.

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