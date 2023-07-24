---
layout: post
title: "What are vector spaces"
tags: test 
---

tags: #math #gilbert-strang 
links: [[Book Wiki]], [[101 Linear Algebra]]

---

There is an old version: [[OLD 101 Vector spaces]]

# 101 Vector spaces[^1]
## What is a space
First what does "space" mean? It means a bunch of vectors. The bunch of vectors is the space of vectors. It isn't just a random bunch. The vectors in the space can do operations that vectors are for. So multiplication and addition of numbers to create a linear combination. What does this mean?

Let's take $R^2$ which means it has two axis, the $x$ and $y$ axis. $R^2$ has two components or dimensions, horizontal ($x$) and vertical ($y$). What are the *valid* vectors inside of $R^2$?

$$\begin{bmatrix} 3 \\ 2 \end{bmatrix}, \begin{bmatrix} 0 \\ 0 \end{bmatrix}, \begin{bmatrix} \pi \\ e \end{bmatrix}, \dots$$

Are these three valid vectors? The answer is yes! That's because as long as the components of the vector contain **real** numbers then the vectors belong in the vector space of $R^2$.

<center>
<img src="https://i.imgur.com/4SSzXpU.png" width="50%" height="50%">
</center>


Drawing out any of these vectors let's say $\begin{bmatrix} 3 \\ 2 \end{bmatrix}$ the first component $3$ is on the $x$ axis so it is the **horizontal** component and $2$ is the **vertical** component. $\pi$ is one component and $e$ is another component. Since real numbers are literally every single number, literally anything you put inside the vector will be in the space of $R^2$ or in other words the three vectors listed above are **in all of $R^2$**.

What about the vector $\begin{bmatrix} 1 \\ 0 \end{bmatrix}$? It is still in $R^2$, it isn't in $R^1$ why? Because $0$ is still a real number! 

### Technical definition

Which means the **technical definition** can be written as such: $v + w$ and $cv$ are in the space. Not only that all linear combinations of $cv + dw$ will product a resultant vector that is inside the space.

## Importance of $\vec{0}$
$\vec{0}$ is the zero vector.  The number of zeroes in it is the same as the number of components or dimensions. So in $R^2$ that would make $\vec{0} = \begin{bmatrix} 0 \\ 0 \end{bmatrix}$, in $R^3$ that would make it $\begin{bmatrix} 0 \\ 0 \\ 0 \end{bmatrix}$ and so on.

The reason $\vec{0}$ or the origin is important is because without it you can't do any multiplication or addition. This makes it that $\vec{0}$ **must** be in **every** vector space, and that includes subspaces.

## What is a sub-space?
When you add two vectors in a space, you produce a vector in that space.

$$
\begin{bmatrix}
3 \\
2
\end{bmatrix} + \begin{bmatrix}
5 \\
6
\end{bmatrix} = \begin{bmatrix}
8 \\
8
\end{bmatrix}
$$

This also applies in multiplication as well. 

$$
-3\begin{bmatrix}
3 \\
2
\end{bmatrix} = \begin{bmatrix}
-9 \\
-6
\end{bmatrix}
$$

These negative numbers are still real numbers. So this resultant vector would still be in $R^2$. So, what is a subspace? A subspace is when you only take portion of an existing space.

$R^2$ has two components $x$ and $y$ and they can be either positive or negative. A subspace of $R^2$ would be to only take the **positive** components. 

<center>
<img src="https://i.imgur.com/PLdX6qc.png" width="50%" height="50%">
</center>

But you can't just say the positive components of $R^2$ makes a subspace. There are rules to follow the two rules is that the subspace is closed by multiplication **and** addition. What does that mean? It means that if a vector in that subspace cannot leave the subspace through multiplication or addition that means it is closed.

Taking a look at the image assuming that two vectors are positive let's say

$$
\begin{bmatrix}
1 \\
2
\end{bmatrix}, \begin{bmatrix}
3 \\
2
\end{bmatrix}
$$

We can add both and the resultant vector would have positive components. Multiply it with a negative scalar and it falls apart. This means that the positive components of $R^2$ is **not** a subspace. Why? Because **it is not closed by multiplication**.

## Example of a valid subspace

<center>
<img src="https://i.imgur.com/npBMiNU.png" width="50%" height="50%">
</center>

Let's take a look at this. There is a line in $R^2$ and vectors along that line. There can be an infinite number of vectors along that line. The core question is **are all vectors along that line in a sub-space?** The answer is yes! Because they are closed by multiplication and addition.

You multiply any of the three vectors and all you do is extend it or make it go in a different direction. You add either vector and you only shorten it. Keep in mind the vector you decide to add must already be on the line itself.

## Another example of an invalid subspace
A *valid* subspace must have a line that goes through the origin so let's prove it with this drawing.

<center>
<img src="https://i.imgur.com/M81dX70.png" width="50%" height="50%">
</center>

Why is it that if the line doesn't pass through $\begin{bmatrix} 0 \\ 0 \end{bmatrix}$, it isn't a valid subspace? Simple, you do some multiplication and the vectors aren't along the line anymore. Multiply any of them by any number and they'll either be too short to touch the line , or too long and just go past it. Multiply any existing vector by $0$ and the line doesn't pass through $\vec{0}$.

## General rule for valid subspaces
First it doesn't how many dimensions there are **all** subspaces must contain the origin. If it doesn't, it isn't a subspace. So, let's go through some examples to establish this general rule.

Let's take $R^2$ for example. What are some valid subspaces in it?
1. All of $R^2$
2. Any line that passes through the origin or *zero*. 

It is important to understand that a line through $R^2$ is not the same as a line through $R^1$. Simply because $R^2$ has two components and $R^1$ has only one component.

3. The zero vector itself is a subspace in $R^2$. Why? Its closed by addition and multiplication, you always stay in $\vec{0}$.


What about for $R^3$?
1. Plane through $\vec{0}$
2. $\vec{0}$ by itself.
3. Line through $\vec{0}$.
4. All of $R^3$

## Where do subspaces come from?

Where do they come from? How do they come out of matrices?

$$
A= \begin{bmatrix}
1 & 3 \\
2 & 3 \\
4 & 1
\end{bmatrix}
$$

You can derive a subspace from the columns of a matrix, now you can't just randomly come up with a few numbers and stick it in a column and call that a subspace for the reasons discussed above. Take $A$ as an example and draw out the column vectors.

<center>
<img src="https://i.imgur.com/aXwvPxO.png" width="50%" height="50%">
</center>

Based on knowledge from [[101 What is a plane]] we can conclude that the column space is a **plane** through $R^3$. That same plane is also through $\vec{0}$. In other words  In other words **all their linear combinations** from a subspace. This is called the column space "C of A" or $C(A)$.

> More on [[101 Column space | column spaces]].

# Practice questions
Here we have two subspaces labelled  $P$ the plane, and $L$ the line.

<center>
<img src="https://i.imgur.com/GOahUOI.png" width="50%" height="50%">
</center>

## Is $P \cup L$ a subspace? [^2]
Meaning taking vectors from both $P$ and $L$.
> My answer is yes because $L$ contains $\vec{0}$.

The answer is no. Because it isn't closed by addition. When you take one vector from $P$ and one from $L$ then add them together the result is a vector that goes off $L$ and $P$. Here is an easy way to visualise this.

<center>
<img src="https://i.imgur.com/3kFIece.png" width="75%" height="75%">
</center>

The purple vector is inside $P$ while the green one is **along** $L$. Now, the green vector can only go in the $xy$ direction. While the purple one can go in all $xyz$. 

$$
\begin{bmatrix}
5 \\
5 \\
0
\end{bmatrix} + \begin{bmatrix}
1 \\
2 \\
3
\end{bmatrix} = \begin{bmatrix}
6 \\
7 \\
3
\end{bmatrix}
$$

You can see how the new vector, will add a new direction to travel in. This resultant vector let's called it $C$ will move **out** of $L$ and no longer be along it. $C$ will also move out of $P$'s space. If it moves out of it, it isn't part of the subspace anymore.

## Does $P \cap L$ give a valid subspace?[^3]

> My answer is yes. Because $\cap$ means vectors in $L$ and $P$. Since $L$ is inside of $P$, that means there are vectors of $P$ that lies along $L$. Therefore since those vectors are part of $L$ and $L$ is a valid subspace, $P \cap L$ is a valid subspace.

Correction on my answer. The answer is yes but for a different reason. $L$ is **not** inside $P$. The only part where $P$ intersects with $L$ is at $\vec{0}$. As $\vec{0}$ itself is its own valid subspace. Since this is easier to understand, I didn't include any images.

## Does $S \cap T$ give a subspace?[^4]
### Abstract understanding
This isn't part of the image and is more abstract. Now, let's say we have two subspaces $S$ and $T$ does their intersection create a subspace? 

> My answer is yes. Since $S$ and $T$ are subspaces their common vectors is at least $\vec{0}$. Just based on this alone I can conclude that $S \cap T$ does give a valid subspace.

The answer is yes but Gilbert Strang gives another reasoning and it is "The sum of vectors in $S \cap T$ is also in the interaction." Why is that the case? Well, that's just how $\cap$ works. Let's say we use two vectors $v$ and $w$. Since $\cap$ wants to extract the **common** vectors $v$ and $w$ are in $S$ and $T$. If you sum them up you remain in $S \cap T$.

When you take an intersection of two subspaces, you'll most likely get a subspace. The resulting subspace is of course going to be smaller.

### Concrete understanding

[^1]: https://youtu.be/JibVXBElKL0?list=PL49CF3715CB9EF31D
[^2]: [Question 1](https://youtu.be/8o5Cmfpeo6g?list=PL49CF3715CB9EF31D&t=405)
[^3]: [Question 2](https://youtu.be/8o5Cmfpeo6g?list=PL49CF3715CB9EF31D&t=463)
[^4]: [Question 3](https://youtu.be/8o5Cmfpeo6g?list=PL49CF3715CB9EF31D&t=583)
