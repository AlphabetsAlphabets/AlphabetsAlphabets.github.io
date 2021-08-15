---
layout: post
title:  "Representing code"
categories: Notes about source
---

# Representing code
The way we represent rlox's grammer. First we need to make up the rules for Lox's grammer. 

## Rules for grammar
We can get grammar by following the grammar rules. Strings are created by following these rules. Strings that are created this way are called __derivations__. So that means all strings are derivations.

The technical term for "grammar rules" or "rules for grammar" is productions. Because these rules __produce__ grammer. A production (rules for the grammar) has a head, and a body. The head is the name of the rule, and the body describes what the rule does.

There are two things a body of a production consists of:
- Terminal. A letter from the grammar's alphabet. A token is a terminal `TokenType::EOF` for example.
- nonterminal. It follows the productions (rules) and generates a token from it.

Productions in action.
```
breakfast -> protein "with" breakfast "on the side";
breakfast -> protein;
breakfast -> bread;

protein -> cooked "eggs";
protein -> "sausage";

bread -> "muffin";
bread -> "toast";

cooked -> "scrambled";
cooked -> "poached";
cooked -> "fried";
```
Productions are made up of two parts the head (it's name), and body (what the rule does). So `breakfast` is the head, and `protein "with" breakfast "on the side"` is the body.

In cases were there are terminals with the same name, whenever it's time to process that nonterminal whichever production it chooses to follow is up to the user.

How to get a derivation
1. Choose a production to start with
2. Follow the nonterminals in the production

Start: `breakfast -> protein "with" breakfast "on the side";`
The first nonterminal is `protein`, so let's pick one production of `protein`; `protein -> cooked "eggs"`, the next production would be `cooked`. Let's choosed `cooked -> "scrambled";`. Then repeat this when `breakfast` shows up in the production that was chosen.

The second nonterminal is `breakfast`. `breakfast -> bread"`, folow the bread production. `bread -> "muffin"`. Then build it all the way back up.

`protein` eventually produces the derivation of `scrambled eggs with muffin on the side`

# Enhancing production notation
It's really long in it's current form. Since there are multiple productions for the `bread` nonterminal. It can be condensed into `bread -> "muffin" | "toast";`. So the new notation is now this.
```
breakfast -> protein "with" breakfast "on the side" | protein | bread;

protein -> ("scrambled" | "poached" | "fried) "eggs" | "sausage";

bread -> "muffin" | "toast" ;
```
This can be kept handy in the file system as a reference.
