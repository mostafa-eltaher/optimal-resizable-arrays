# Optimal resizable array

This repo is a demo implementation of [Resizable Arrays in Optimal Time and Space](https://cs.uwaterloo.ca/research/tr/1999/09/CS-99-09.pdf) in Zig.

Currently, only the "Singly Resizable Array" data structure is implemented.

## Mistake in the `Locate` procedure
In the "Optimal Resizable Arrays" paper, there is a mistake in the `Locate` procedured (Algorithm 3, step 3, page 8 and the same on Algorithm 6, step 5.a, page 13 )

$p$ is the number of data blocks in superblocks prior to $SB_k$.

In the paper it is caluculated as:
$$p = 2^k - 1$$
which is drived from:
$$p = \sum_{j=0}^{k-1} 2^j$$

However, it should be:
$$p = \sum_{j=0}^{k-1} 2^{\lfloor j/2 \rfloor}$$

which can be caculated as:

$$p = 2(2^{\lfloor k/2 \rfloor} - 1) +  (k \mod{2}) 2^{\lfloor k/2 \rfloor}$$

Where:

$2(2^{\lfloor k/2 \rfloor} - 1)$ is double $\sum_{j=0}^{\lfloor k/2 \rfloor - 1} 2^j$. That is double the sum of the gemetric series up till $\lfloor k/2 \rfloor -1$ 

$(k \mod{2}) 2^{\lfloor k/2 \rfloor}$ is a conditional term of $2^{\lfloor k/2 \rfloor}$ to be added only when $k$ is odd
