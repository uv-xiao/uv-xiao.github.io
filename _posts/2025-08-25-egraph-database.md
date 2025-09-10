---
layout: post
title: egraph-database
date: 2025-09-25 00:00:00
description:
tags:
categories:
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  # sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

I learn relationship between e-graphs and databases.

References:
* Yihong Zhang's blog, https://effect.systems/
* Semantic Foundations of Equality Saturation, https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ICDT.2025.11
* Database Theory in Action: Search-based Program Optimization, https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ICDT.2025.34

## Semantic Foundations of Equality Saturation

### Notation for Term Rewriting Systems (TRS)

$$
\begin{aligned}
\text{Signature } & \Sigma := \{ f_1, f_2, \dots\}  \text{, finite set of function symbols (constructors) with given arities } \\
\text{Variables } & V := \{ x, y, \dots \}  \text{, finite set of variables } \\
\text{Terms } & T(\Sigma, V) \text{ set of terms constructed inductively using symbols from } \Sigma \text{ and variables from } V \\
\text{Pattern } & p \in T(\Sigma, V) \text{ a member of } T(\Sigma, V) \\
\text{Ground term } & t \in T(\Sigma) \stackrel{\text{def}}{=} T(\Sigma, \emptyset) \text{ a member of } T(\Sigma, \emptyset) \\
\text{Substitution } & \sigma : V \rightarrow T(\Sigma) \text{ function from variables to terms } \\
& u[\sigma] \text{ term obtained by applying the substitution } \sigma \text{ to } u \\
\text{Rewrite rule } & r = lhs \rightarrow rhs \text{ where both } lhs \text{ and } rhs \text{ are patterns, and the variables in } rhs \text{ are a subset of those in } lhs \\
\text{TRS } & \mathcal{R} \text{ set of rewrite rules } \\
\text{Rewrite relation } & \rightarrow_{\mathcal{R}} \text{ relation defined by rewrite rules } \\
& \text{defined as follows: } \\
& \text{if } r = lhs \rightarrow rhs \text{ is a rewrite rule in } \mathcal{R}\text{, and } \sigma \text{ is a substitution, then } \\
& lhs[\sigma] \rightarrow_{\mathcal{R}} rhs[\sigma] \\
& \text{if } u \rightarrow_{\mathcal{R}} v \text{ then } \\
& f(w_1, \ldots, w_{i-1},u,w_{i+1},\ldots w_k) \rightarrow_{\mathcal{R}} f(w_1, \ldots, w_{i-1},v,w_{i+1},\ldots w_k) \\
\text{Rewrite closure } & \rightarrow_{\mathcal{R}}^* \text{ the reflexive and transitive closure of } \rightarrow_{\mathcal{R}} \\
& \text{also define } (\leftarrow_{\mathcal{R}})\stackrel{\text{def}}{=}(\rightarrow_{\mathcal{R}})^{-1} \\
& (\leftrightarrow_{\mathcal{R}})\stackrel{\text{def}}{=}(\rightarrow_{\mathcal{R}})\cup(\leftarrow_{\mathcal{R}}) \\
& (\approx_{\mathcal{R}})\stackrel{\text{def}}{=}(\leftrightarrow_{\mathcal{R}})^+ \\
\text{Congruence closure } & \approx_{\mathcal{R}}
\end{aligned}
$$



### E-graphs as Tree Automata


$$
\begin{aligned}
\text{Tree automation } & \mathcal{A} = \langle Q, \Sigma,\Delta\rangle  \\
& \text{where } Q \text{ is a set of states, } \Sigma \text{ is a signature, and } \Delta \text{ is a set of transitions} \\
\text{Transition } & f(q_1,\ldots, q_n)\rightarrow q \text{ where } q,q_1,\ldots, q_n\in Q, f \in \Sigma \\
\text{TRS } & \Delta \text{ is a TRS for } \Sigma \cup Q \\
\text{Rewrite relation } & \rightarrow_{\mathcal{A}}^* \\
\text{Language } & \mathcal{L}(\mathcal{A}) \stackrel{\text{def}}{=} \left \{ t \in T(\Sigma \cup Q) \mid \exists q \in Q, t \rightarrow_{\mathcal{A}}^* q \right \}
\end{aligned}
$$

> E-node is transition. E-class is state.
{: .block-tip }


<div class="row mt-3">
    <div class="col-sm mt-3 mt-md-0">
        {% include figure.liquid loading="eager" path="assets/img/in_posts/egraph-tree-automata.png" class="img-fluid rounded z-depth-1" %}
    </div>
</div>


#### Partial Equivalence Relation (PER) and Partial Congruence Relation (PCR)

Define *partial equivalence relation* (PER): binary relation $\approx$ that is symmetric and transitive, over a set $A$. $supp(\approx) \stackrel{\text{def}}{=} \{ x \mid x \approx x \} \subset A$.

PER over term set $T(\Sigma)$ is *congruent* if $s_i = t_i$ for $i=1,\dots,n$ and $f(s_1, \dots, s_n) \in supp(\approx)$ impl $f(s_1, \dots, s_n) \approx f(t_1, \dots, t_n)$. A PER is *reachable* if $f(s_1, \dots, s_n) \in supp(\approx)$ implies $s_i\in supp(\approx)$. 

Define *Partial Congruence Relation* over term set $T(\Sigma)$: a *congruent* and *reachable* PER.

> Don't very understand the PER/PCR definition. But naturally, an e-graph $G$ induces a PCR $\approx_G$. 
{: .block-warning }

Define PCR $\approx_G$ of e-graph $G$: $t_1 \approx t_2$ if there exists some E-class $c$ in $G$ that accepts
both $t_1$ and $t_2$, i.e. $t_1\rightarrow^*_G c \text{ and } t_2\rightarrow^*_G c$.

Theorem: For any PCR $\approx$ over $T(\Sigma)$, there exists a unique $G$ such that $(\approx_G) = (\approx)$.

#### Congruence closure over e-graph

Tree automata *homomorphism* $h: \mathcal{A}\rightarrow \mathcal{B}$.

Define $\mathcal{A} \sqsubset \mathcal{B}$, if $\exists h:h: \mathcal{A}\rightarrow \mathcal{B}$.

$\sqsubset$ is partial order for e-graphs.

Congruence closure: For arbitrary $\mathcal{A}$, there exists a unique minimal e-graph G (CC($\mathcal{A}$)) such that $\mathcal{A} \sqsubset G$.