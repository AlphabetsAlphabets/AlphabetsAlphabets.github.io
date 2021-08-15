---
layout: post
title:  "Implementing an abstract syntax tree"
categories: Notes about source
---

After learning about how the [productions](https://yjh16120.github.io/rlox/notes/about/source/2021/08/08/Representing-code.html) work in general it's time to implement productions specifically for rlox.

*Production of rlox*
```
expression     -> literal | unary | binary | grouping ;
literal        -> NUMBER | STRING | "true" | "false" | "nil" ;
grouping       -> "(" expression ")" ;
unary          -> ( "-" | "!" ) expression ;
binary         -> expression operator expression ;
operator       -> "==" | "!=" | "<" | "<=" | ">" | ">=" | "+"  | "-"  | "*" | "/" ;
```
- Unary, only two terminals are in there '-', and '!'. To negate and perform the logical not operation respectively.
- Binary. Infix artihmetic (+, -, *, /), and logical operators (==, !=, <, etc.) .
- the reason `NUMBER`, and `STRING` are in all caps is because they are both one lexeme that can carry different values.
    - The `STRING` token can carry both `String("Hi there.")`, and `String("Hello there.")`. Same goes for `Number`, it can carry different numbers.
    - Whereas the `EqualEqual` token ('==' character) will always be '==' never something else.
- Literals are numbers, strings, booleans, nil/none.

Since `literal`, `unary`, `binary`, and `grouping` fall under expression. Usually classes of each of those four will be created, and inherits from an expression class. But because this is Rust, classes don't exist. Instead tuple structs and enums will be used to replicate this behaviour.

```rust
// in ast.rs
#[derive(Clone)]
struct Binary {
    left: Box<Expr>,
    operation: Token,
    right: Box<Expr>,
}

#[derive(Clone)]
struct Unary {
    left: Box<Expr>,
    operation: Token,
}

#[derive(Clone)]
struct Grouping {
    grouping: Box<Expr>,
}

#[derive(Clone)]
enum Literal {
    String(String),
    Number(f64),
}

#[derive(Clone)]
enum Expr {
    Binary(Binary),
    Unary(Unary),
    Grouping(Grouping),
    Literal(Literal),
}

trait Visitor<T> {
    fn visit(&mut self, expr: &Expr) {
        match expr {
            Expr::Unary(unary) => todo!(),
            Expr::Binary(binary) => todo!(),
            Expr::Literal(literal) => todo!(),
            Expr::Grouping(grouping) => todo!(),
        }
    }
}
```
After finding a way to differentiate betweent the different expressions, the next step is to process them. For when an expression is passed in, it will be either unary, binary, literal, or grouping. Grouping, binary, and unary can eventually be broken down into literal. Where literal can contain either a `String`, or an `f64`.

The ultimate goal is to return either an `f64` or a `String` all the way up the call stack. To eventually add the literals together to form a valid expression. 
