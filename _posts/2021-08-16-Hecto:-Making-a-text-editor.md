---
layout: post
title: "Hecto: Making a text editor"
categories: hecto
---

* TOC
{:toc}

---


# Cargo.toml specifications
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

> Character to byte -> `char as u8`  
> byte to char -> `byte as char`

# Creating the editor
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
	print!("{}", termion::clear::All);
	print!("{}{}", termion::clear::All, termion::cursor::Goto(1, 1));
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
Quitting the program was done by using the `panic!` macro, but that leaves an ugly output in stderr. `should_quit` is a bool, set to true when `ctrl+q` is pressed. If `should_quit` is true, exit program.

![Using panic! to exit](/images/hecto/using_panic_macro_to_exit.png){:class="img-responsive"}
<h5 style="text-align: center; font-style: italic;">Using panic! to exit</h5>

`termion::clear::All`, and `termion::cursor::Goto(1, 1)`. Clears the screen then goes to row 1, column 1.

the `process_keypress` has been condensed down, before the byte code and the character would printed in that function. Now it has `read_key` a helper function. Basically it grabs the current key pressed and returns it as an event. The `?` for when it's called is the same as calling `unwrap`. And if `pressed_key` matches `ctrl+q`, `should_quit` is set to `true`, quitting the program.

## Drawing tidles (~) like vim
First get the height of the terminal window a struct will represent this data. `termion` provides a method to get the width, and height of the terminal window.
```rust
pub struct Terminal {
    size: (u16, u16)
}

impl Terminal {
    pub fn new() -> Result<Self, std::io::Error> {
        let size = termion::terminal_size()?; // <- gets terminal dimensions
        let term = Self {
            size: (size.0, size.1)
        };

        Ok(term)
    }

    pub fn size(&self) -> (u16, u16) {
        (self.size.0, self.size.1)
    }
}
```

Add a new field to `Editor`
```rust
Editor {
    should_quit: bool,
    terminal: Terminal
}
```
Create a draw function
```rust
fn draw_tidles(&self) {
    for _ in 0..self.terminal.size.1 {
        println!("~\r");
    }
}
```
Then reset the cursor to `1, 1` after the call.
```rust
if self.should_quit {
    break;
} else {
    self.draw_tildes();
    print!("{}", termion::cursor::Goto(1, 1));
    io::stdout().flush();
}
```
*Moved all functions related to the terminal into the implementation of `Terminal`.*

## Touching up
```rust
    // moved `refresh_screen` back to editor.rs
    pub fn refresh_screen(&self) -> Result<(), std::io::Error> {
	Terminal::clear_screen();
        Terminal::cursor_hide();
        Terminal::cursor_position(0, 0);
        Terminal::flush()
    }
```
Clearing the screen each time is overkill, to fix it in the `draw_tildes` function, it should clear the current line instead. So when the window moves down, it doesn't just clear the entire screen.
```rust
    pub fn clear_current_line() {
        print!("{}", termion::clear::CurrentLine);
        Self::flush();
    }
```
Then in `draw_tildes`
```rust
    fn draw_tildes(&self) {
        for _ in 0..self.terminal.size().1 {
            Terminal::clear_current_line();
            println!("~\r");
        }
    }
```

## Displaying a welcome message
Drawing the welcome message will be called when the tidles are being drawn.
```rust
    fn draw_tildes(&self) {
        let height = self.terminal.size().1;
        for row in 0..height - 2 {
            Terminal::clear_current_line();
            if row == height / 3 {
                self.draw_welcome_message();
            } else {
                println!("~\r");
            }
        }
    }
```
```rust
    fn draw_welcome_message(&self) {
        let mut welcome_message = format!("Hecto -- version {}\r", VERSION);         
        let width = self.terminal.size().0 as usize;
        let len = welcome_message.len();

        let padding = width.saturating_sub(len) / 2;
        let spaces = " ".repeat(padding.saturating_sub(1));

        welcome_message = format!("~{}{}", spaces, welcome_message);
        welcome_message.truncate(width);

        println!("{}\r", welcome_message);
    }
```

To illustrate centering the text.
```
Assume the width of the screen in 24 chars
+------------------------+
|                        |
|                        |
+------------------------+
```
To center the text in the center with 4 chars, you must make space so `width - 4`.
This places the 4 character string right up to the edge of the screen.
```
+------------------------+
|                    TEXT|
|                        |
+------------------------+
```
Then half the length of the width which places the "T" in "TEXT" starting from the 12th character.
```
+------------------------+
|           TEXT         |
|                        |
+------------------------+
```
It's not exactly centered but close enough.

# Functionality
## Moving the cursor
Making the cursor move means in the places where `Terminal::cursor_position` was called and set to `(0, 0)` is now pointless. That function will now that a `Position` as an argument. `Position` will be in `editor.rs` and **not** `terminal.rs` because it's the position of the cursor **in the document**, not in the terminal.

```rust
    pub fn cursor_position(pos: &Position) {
        // using `saturating_add` prevents the buffer from overflowing.
        let Position { mut x, mut y } = pos;
        let x = x.saturating_add(1) as u16;
        let y = y.saturating_add(1) as u16;

        print!("{}", termion::cursor::Goto(x, y));
        Self::flush();
    }
```
Next creating `Position` in `editor.rs`
```rust
pub struct Position {
    pub x: usize,
    pub y: usize,
}
```
Detecting the key press will be done in the `process_keypress` function (lmao obviously).
```rust
    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let Position { mut x, mut y } = self.cursor_position;
        let pressed_key = Terminal::read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            Key::Up | Key::Down | Key::Left | Key::Right => self.move_cursor(pressed_key),
            _ => (),
        }
        Ok(())
    }
```

A new method in `Editor` called `move_cursor` will be implemented. The cursor will be able to move any where within the bounds of the screen.
```rust
    fn move_cursor(&mut self, key: Key) {
        let Position { mut x, mut y } = self.cursor_position;

        let size = self.terminal.size();
        let width = size.width.saturating_sub(1) as usize;
        let height = size.height.saturating_sub(1) as usize;

        match key {
            Key::Up => y = y.saturating_sub(1),
            Key::Down => {
                if y < height {
                    y = y.saturating_add(1)
                }
            },
            Key::Left => x = x.saturating_sub(1),
            Key::Right => {
                if x < width {
                    x = x.saturating_add(1)
                }
            },
            _ => (),
        }

        self.cursor_position = Position { x, y }
    }
```
<h5 style="text-align: center; font-style: italic;">(0, 0) starts in the top left corner, not the centre of the screen.</h5>

```rust
            if self.should_quit {
                Terminal::clear_screen();
                Terminal::cursor_show();
                break;
            } else {
                self.draw_tildes();
                Terminal::cursor_position(&self.cursor_position);
            }
```
The change here is that instead of setting the cursor to `(0, 0)` after drawing the tidles (which is every single time unless it's to quit hecto). Will cause the cursor to not move despite the functions being implemented. The fix is to just move the cursor to the current position of the cursor which doesn't change where it is at all.

## Adding modes (5010ba7)
A struct that has the different modes will be used. `PartialEq` will save me from using too many match statements.
```rust
#[derive(PartialEq)]
enum Mode {
    Insert,
    Normal
}
```

Made two functions to handle the inputs in normal and insert mode.
```rust
    fn normal_mode(&mut self, key: Key) {
        let Position { mut x, mut y } = self.cursor_position;

        let size = self.terminal.size();
        let width = size.width.saturating_sub(1) as usize;
        let height = size.height.saturating_sub(1) as usize;

        match key {
            Key::Char('k') => y = y.saturating_sub(1),
            Key::Char('j') => {
                if y < height {
                    y = y.saturating_add(1)
                }
            }
            Key::Char('h') => x = x.saturating_sub(1),
            Key::Char('l') => {
                if x < width {
                    x = x.saturating_add(1)
                }
            }

            Key::Char('i') => {
                self.mode = Mode::Insert;
            }
            _ => (),
        }

        self.cursor_position = Position { x, y }
    }

    fn insert_mode(&mut self, key: Key) {
        match key {
            Key::Esc => {
                self.mode = Mode::Normal;
            }
            _ => (),
        }
    }
```

The move cursor function will need to be modified
```rust
    fn move_cursor(&mut self, key: Key) {
        if self.mode == Mode::Normal {
            self.normal_mode(key);
        } else {
            self.insert_mode(key);
        }
    }
```

To switch between different modes the `process_keypress` function will be modified
```rust
    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let Position { mut x, mut y } = self.cursor_position;
        let pressed_key = Terminal::read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            Key::Char('j') | Key::Char('k') | Key::Char('l') | Key::Char('h') => {
                self.move_cursor(pressed_key)
            }
            Key::Esc => self.change_mode(Mode::Normal),
            Key::Char('i') => self.change_mode(Mode::Insert),
            _ => (),
        }
        Ok(())
    }
```

`change_mode` will change the mode (lmao yeah duh)
```rust
    fn change_mode(&mut self, change_to: Mode) {
        self.mode = change_to;
    }
```

## Adding in 0 and S
Very simple change in `process_keypress` modify the match arm that uses `move_cursor`
```rust
            Key::Char('j') | Key::Char('k') | Key::Char('l') | Key::Char('h') 
                |  Key::Char('0') | Key::Char('S') => {
                self.move_cursor(pressed_key)
            }
```
In the `normal_mode` function add these arms
```rust
            Key::Char('0') => x = 0,
            Key::Char('S') => x = width,
```
Since `g` goes to the beginning of the file, set y to 0, same reasoning for `0` the start of the line is when x is 0. When going to the bottom of the screen with `G` y is set to `height`.

# Viewing files
In `document.rs` a new function `open` is to be defined, it's going to open a file.
```rust
    pub fn open(filename: &str) -> Self {
        let contents = fs::read_to_string(filename).expect("Unable to open file.");
        let mut rows = vec![];

	// lines() strips all whitespace characters at the end of each line.
        for value in contents.lines() {
            rows.push(Row::from(value));
        }

        Self { rows }
    }
```

This changes the `new` method for `Editor`
```rust
    pub fn new() -> Self {
        let args: Vec<String> = env::args().collect();
        let document = if args.len() > 1 {
            let file_name = &args[1];
            Document::open(file_name)
        } else {
            Document::default()
        };

        Self {
            mode: Mode::Normal,
            should_quit: false,
            document,
            terminal: Terminal::new().expect("Failed to initialize terminal."),
            cursor_position: Position::default(),
        }
    }
```
Checking if args is greater than 1 because `args[0]` is the name of the program, and `args[1]` onwards are actual arugments. If it's greater than 1 it means a file is passed in. And it will load the contents of that document into the editor, else it will load in an empty document into the editor.

To draw all of the text onto the screen.
```rust
impl Row {
    pub fn render(&self, start: usize, end: usize) -> String {
	// start will always be smaller than end due to `min`
        let end = cmp::min(end, self.string.len());
        let start = cmp::min(start, end);
        self.string.get(start..end).unwrap_or_default().to_string()
    }
}
```
This function will always make sure to return a substring (assuming `start`, and `end` are reasonable numbers). `get` can be used on `&str`, and `String` to get substrings.

In `draw_row` 
```rust
    fn draw_row(&self, row: &Row) {
        let start = 0;
        let end = self.terminal.size().width as usize;
        let row = row.render(start, end);

        println!("{}\r", row);
    }
```
`render` as discussed earlier will print extract a substring or return `None`, then print out the substring.

## Scrolling
### Vertical scrolling
a new field offset of type `Position` will need to be added to `Editor`
```rust
pub struct Editor {
    mode: Mode,
    offset: Position,
    should_quit: bool,
    document: Document,
    terminal: Terminal,
    cursor_position: Position,
}
```
This will be used to handle scrolling vertically (up and down). The value of `offset.x`, and `offset.y` will not be determined on startup. Instead it is initialized in the new `scroll` function.

```rust
    fn scroll(&mut self) {
        let Position { x, y } = self.cursor_position;
        let width = self.terminal.size().width as usize;
        let height = self.terminal.size().height as usize;
        let mut offset = &mut self.offset;

        if y < offset.y {
            offset.y = y;
        } else if y >= offset.y.saturating_add(height) {
            offset.y = y.saturating_sub(height).saturating_add(1);
        }

        if x < offset.x {
            offset.x = x;
        } else if x >= offset.x.saturating_add(width) {
            offset.x = x.saturating_sub(width).saturating_add(1);
        }
    }
```
`offset` keeps track of which row the user is at in the file. 

Assuming `y` is 24, and offset.y is 0, i the first `if` the second condition would be true. Then the added height is subtracted from `offset.y` and 1 is added to it. This will allow for scrolling, as `offset.y` is used in here to determine what lines should be drawn onto the screen:
```rust
if let Some(row) = self.document.row(terminal_row as usize + self.offset.y) {
    self.draw_row(row);
} else if self.document.is_empty() && terminal_row == height / 3 {
    self.draw_welcome_message();
} else {
    println!("~\r");
}
```
As the goal is to scroll downwards, the row that is obtained from the `row` method [^1] will be increased by 1, thereby ignoring the previous row, and rendering everything else instead. As the value of `offset.y` increases, the row that was rendered will be ignored in favour of a new one. The same concept is applied to scrolling horizontally. Where it ignores a character instead of an entire line.

### Horizontal scrolling
Horizontal scrolling is implemented this way.
```rust
let mut width = if let Some(row) = self.document.row(y) {
    row.len()
} else {
    0
};
```
This is used to determine the width of the line, meaning how many characters long it is. If the width cannot be determined set it to 0, as `row` functions by getting the index. Right now the cursor can move any where in the document, but it can only move as far as the longest row. If there is a row shorter than the longer row, it will be able to move beyond the width of the current row.

The fix for this is checking if the x position of the cursor is greater than the width of the current row. If it is set the x position to the width, to make sure the cursor can only move as far as right as the length of the current row.

```rust
// adjusts the width the the length of the row
width = if let Some(row) = self.document.row(y) {
    row.len()
} else {
    0
};

if x > width {
    x = width + 1; // <-- `width + 1` not in the guide
}
```

### Adding a fix
Because the cursor position has the values of `offset.x`, and `offset.y` added to it's value. It will need to be subtracted from it. So in `run()` in `editor.rs`

```rust
loop {
    if self.should_quit {
    	self.terminal.clear_screen();
    	break;
    } else {
    	self.draw_rows();
    	let pos = Position {
	    x: self.cursor_position.x.saturating_sub(self.offset.x),
	    y: self.cursor_position.y.saturating_sub(self.offset.y),
    	};
    
    	self.terminal.cursor_position(&pos);
    }
    
    if let Err(error) = self.process_keypress() {
    	panic!(error);
    };
}
```

## Adding in more keys
The W and B key in vim moves the cursor forward, and backward respectively until the first non whitespace character with the exception of the whitespace the cursor is currently on, or adjacent to.

### Adding in the 'w' key
In `normal_mode`, another match arm is added
```rust
if let Some(row) = self.document.row(y) {
	if let Some(contents) = row.contents().get(x..) {
		let mut index = 0;
		for (count, ch) in contents.chars().enumerate() {
			if !ch.is_ascii_alphabetic() {
				index = count;
				break;
			}
		}

		if x >= width && y < height {
			y += 1;
			x = 0;
		} else {
			x = x.saturating_add(index + 1);
		}

	}
}
```
`contents` is a simple function that returns the text in the current row. And `get`, gets a substring of that row. To illustrate:  

```
# See more {k}eys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
```
Take this line, and the cursor position is found by finding what text is surrounded by {foo}, in this case the cursor is at the 'k' character in 'keys'. To move forward and stop at the first **non ascii alphabet**, excluding the word the cursor is at, looping through each character with `enumerate`. Taking note of `count`, and setting it to `index`. Because `count` is the number of characters that has passed to read the non ascii alphabetic character. 

The if statement at the bottom will allow the cursor to move to the start of the second line, assuming the cursor is at the end of the current line, and there is a next line (`y < height` part). Then increment y by 1, and set x to 0 (the start of the line). If that isn't the case, then just add the number of characters passed into the current x position to move it.

And the 'b' is the reverse of the 'w' so it won't be specified in here, the concepts are all the same. [^2]

### Scrolling up and down a page.
The keys responsible for this will be captial 'J', and 'K'.

# Footnotes
[^1]: The `row` method will index into the `Row` struct which has a field containing a vector of strings, where each element is a row in a file, then grab that role using the provided index.

[^2]: [The implementation of the 'b' key](https://github.com/YJH16120/hecto/blob/master/src/editor.rs#L143)

