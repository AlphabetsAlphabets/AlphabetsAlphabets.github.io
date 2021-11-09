---
layout: post
title:  "keig: A BitTorrent client written in python"
categories: keig
---


# Table of Contents
* TOC
{:toc}

---

# Why a BitTorrent client?
Well I've always wanted to work with async/asyncio but all my efforts have lead to mostly nothing. As I give up pretty easily. I found a guide by [Markus Eliasson](https://markuseliasson.se/article/bittorrent-in-python/). Just like the Hecto guide, I will branch off from the guide, and put my own spin on things after I've gotten a good grasp on what I'm supposed to do. But I will revisit the guide from time, to time to take a look at the implementation. As an aside, the only thing is having a basic knowledge of async/asyncio, I suggest a combination of both [Markus'](https://markuseliasson.se/article/introduction-to-asyncio/) tutorial on async, along with [Brett Cannon's](https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/) guide. I read those posts as a base for async/asyncio. And constantly having to to write "async/asyncio" is annoying so from this point onwards I'm just going to use both of them interchangably.

# The good stuff

