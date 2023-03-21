---
layout: post
title: "Implementing the iterator trait in Rust"
tags: rust
---

# Basic implementation
The `Iterator` trait allows for the creation of an iterator. If the trait is implemented for a `struct`, the `struct` gets access to every single function that an iterator would have access to `find`, `nth`, `position`, etc.

I wish to define `Iterator` for `Message`.

```rust
pub struct Message {
    index: usize,
    pub msg: String,
}
```

As an iterator, I want to it do only one thing. Return characters from the `msg` field. An iterator will need to keep track of its current position and an index is needed.

The `Iterator` trait looks like this.
```rust
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}
```

It defines a custom type `Item` and a required method that returns an `Option` of `Self::Item`.
1. What is `Item`? I want the iterator to return characters, therefore, `Item` is a char.
2. The implementation of `next`.

A `String` can be converted to `Vec<char>` like this:
```rust
let chars: Vec<char> = self.msg.chars().collect();
```

Then `get` can be used on it to get the character as some index. The index to grab it on would be `self.index`. Iterators will go forward so `self.index` will be incremented at the end of the function call. Therefore, the implementation of `next` as as follows:

```rust
impl Iterator for Message {
    type Item = char;

    fn next(&mut self) -> Option<Self::Item> {
        let chars: Vec<char> = self.msg.chars().collect();
        let char = match chars.get(self.index) {
            Some(char) => Some(char.to_owned()),
            None => None,
        };

        self.index += 1;
        char
    }
}
```

So, you can do whatever an iterator can with with `Message`. 

# Implementation of `nth`
## Justification
Now, `Message` can do anything an iterator can or can it? Take for instance, finding the position of the comma and grabbing it.

```rust
let mut msg = Message::new("Hello, World!".to_string());
let pos = msg.position(|c| c == ',').unwrap();
println!("{}", msg.nth(pos).unwrap());
```

But, the printed value isn't `,` it's `d`. Checking the result of `pos` through `println!` reveals that the output is `5` which is correct.

This has to do with the default implementation of `nth`.

```rust
fn nth(&mut self, n: usize) -> Option<Self::Item> {
	self.advance_by(n).ok()?;
	self.next()
}
```

What's `advance_by`? According to the documentation:

> Advances the iterator by n elements.

So, to find out what is does on a `String`. Let's use the function. 

```rust
let x = String::from("Hello, there");
x.nth(5);
```

To put it simply, it doesn't.

```
error[E0599]: no method named `nth` found for struct `String` in the current scope
  --> src/main.rs:48:7
   |
48 |     x.nth(5);
   |       ^^^ method not found in `String`

For more information about this error, try `rustc --explain E0599`.
error: could not compile `slice` (bin "slice") due to previous error
```

That's because in order to use `nth` the type has to implement the `Iterator` trait. `String` is not an iterator. Which is why a custom implementation of `nth` is required.

> As for why `msg.nth` doesn't fail but calling `nth` directly on a `String` does, I have no idea. But, the `nth` equivalent for `String` would be `String::get`.

### Implementation
While `nth` doesn't apply to `String` it does for `Chars`.

```rust
    fn nth(&mut self, index: usize) -> Option<Self::Item> {
        self.index += index;
        self.msg.chars().nth(self.index)
    }
```

First, convert `String` into the characters then call `nth` on it. Then the code above will run just fine. But, why is it not implemented like this?

```rust
    fn nth(&mut self, index: usize) -> Option<Self::Item> {
        let mut chars = self.msg.chars();
        chars.nth(index)
    }
```

Well the reason is so that when I or anyone else uses it, no one gets confused. Because, the first implementation is how iterators work to begin with. Best to fit in that stick out, especially when its already been standardised.
