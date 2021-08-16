---
layout: post
title: "Hecto: Making a text editor"
categories: hecto
---

**Cargo.toml**
```toml
[package]
name = "hecto"
version = "0.1.0"
edition = "2018"

[dependencies]
termion = "1"
```

`termion` is used to go into raw mode, raw mode won't let us input characters directly into the screen, enter also doesn't need to be pressed for it to count as input. This is handy because the byte code for each button can be extracted. The only down side for this is that the in order for output to be shown from user input, it must be done manually.

The usual method is to take in user input, then process it but the standard way requires the user to press a character then the enter key, after the enter key is pressed only will the character be processed. Raw mode skips that and the character can be processed immediately.

```rust
use std::io::{self, stdout};

use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;

fn main() {
    let _stdout = stdout().into_raw_mode().unwrap();

    for key in io::stdin().keys() {
        match key {
            Ok(key) => match key {
                Key::Char(c) => {
                    if c.is_control() {
                        println!("{:?}\r", c as u8);
                    } else {
                        println!("{:?} ({})\r", c as u8, c);
                    }
                },
                Key::Ctrl('q') => break,
                _ => println!("{:?}\r", key),
            },
            Err(e) => panic!(e),
        }
    }
}
```

Every key press is matched and then checks to see if that character is a printable character with `is_control()`. Printable characters are from ASCII codes 32-126, 0-31, and 127 are all control characters. Control characters are things like the backspace key, control key combinations, etc.

If it is a control character then the character will be converted to bytes and printed out. If the key combination pressed is ctrl+q it will end the process.

> Character to byte = `char as u8`
> byte to char = `byte as char`
