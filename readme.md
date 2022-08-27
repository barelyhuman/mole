# molecule 

> A module centric generative / meta language

Will probably get dropped 

### TODO 
- [ ] A very basic tokenizer/lexer (not handling 100 failure cases but very tight and easy syntax cases)
- [ ] A parser that can create a proper AST for the above lexer this should try to handle as much context as possible.
- [ ] Backends for transpiling, start with a JS backend (since it's going to be a lot easier to implement)

### Why?
I like lua as a language and I might just use it for everything small and modular but there are cases where I'd like something to translate to JS and I forget what can and cannot be translated to JS so... 

Also, I wanted to see if I was to create something small and tiny, how much work it was. 

### Why in Nim ? 

- It's simple 
- It already handles most of the meta programming use cases for me 
- Easy to re-implement C level specs if I ever wish to. 



