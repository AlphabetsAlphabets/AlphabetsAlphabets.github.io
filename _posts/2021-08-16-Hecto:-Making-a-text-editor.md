---
layout: post
title: "Hecto: Making a text editor"
categories: hecto
---

**Dependancies (Cargo.toml)**
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

# Creating the editor module
Everything related to editing will be in that module. First are the imports.
```rust
use std::io::{self, stdout, Write};

use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;
```
The editor struct
```rust
pub struct Editor {
    should_quit: bool
}
```
Next are the functions
```rust
pub fn read_key() -> Result<Key, std::io::Error> {
    loop {
        if let Some(key) = io::stdin().lock().keys().next() {
            return key;
        }
    }
}

impl Editor {
    pub fn new() -> Self {
        Self {
            should_quit: false
        }
    }

    fn refresh_screen(&self) -> Result<(), std::io::Error> {
        // This byte clears the screen
        print!("\x1b[2J");
        io::stdout().flush()
    }

    pub fn run(&mut self) {
        let _stdout = stdout().into_raw_mode().unwrap();

        loop {
            if let Err(error) = self.refresh_screen() {
                panic!(error);
            };

            if self.should_quit {
                break;
            };

            if let Err(error) = self.process_keypress() {
                panic!(error);
            };

        }
    }

    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let pressed_key = read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            _ => (),
        }
        Ok(())
    }
}
```
Quitting the program was done by using the `panic!` macro, but that leaves an ugly output in stderr. Instead adding the `should_quit` field and setting it to `false` by default, then checking if `should_quit` is `true` or `false`, if `true` then break ending the program, if `false` continue running the program.  
![Using panic! to exit](/images/hecto/using_panic_macro_to_exit.png){:class="img-responsive"}
<h5 style="text-align: center;">Using panic! to exit</h5>

`\x1b[2J` by putting that escape character into the `print!` macro it clears the screen.

the `process_keypress` has been condensed down, before the byte code and the character would printed in that function. Now it has `read_key` a helper function. Basically it grabs the current key pressed and returns it as an event. The `?` for when it's called is the same as calling `unwrap`. And if `pressed_key` matches `ctrl+q`, `should_quit` is set to `true`, quitting the program.
