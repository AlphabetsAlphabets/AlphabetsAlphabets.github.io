---
layout: post
title: "Redoing the whole thing :D"
tags: actt
---

# Why the sudden re-write?
Wow, surprising. How knew that when something wasn't planned, it would be difficult to maintain to the point that redoing the whole thing makes it easier? Who would've thunk it?


## Improper documentation
I came back to this project after a few months of doing nothing for it due to school work, assignments and all that jazz. Problem is that my documentation is on things that aren't relevant. Such as confusing lines of code. This created a need to redocument everything.

## Random bits of unused code
There are random bits of code that deal with a user's preferences. I included user preferneces, when the main features aren't even finished yet. They are completely littered with random bugs and I decided to add more things the project to worry about. This provided an unnecessary amount of overhead and I couldn't just focus on the one thing.

There were checks for these user preferences in the logic, which meant they were simply "if preference is selected, panic." Which only makes things more complicated without reason.

## Choosing the wrong library
egui is great but not for what I want. It is a perfectly fine library, don't get me wrong. That's why I was able to developing using egui for such a long time. It being able to compile to WASM is also great, which means egui can truly be cross platform. The problem I have with egui is that it is immediate mode. Yes, it is a new programming style (pattern?) but I am not used to it. There are benefits yes, but, I believe that it would be better to use a retained mode library.

Something like tauri or iced would be better. I'm not too sure what the differences are at the time of writing, but, I'm doing more research on it.

# Summary
The lack of proper planning and research resulted in the need for a rewrite. The code base is also incredibly messy and has a huge lack of documentation, there were also if statements that "gated" specific features based on user preferences, and user preferences weren't even implemented yet. I was focusing on too much and there was a lot of noise in the project.
