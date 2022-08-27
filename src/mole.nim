import std/[strutils, re, json]


var variableCharacters = re"[a-zA-Z]"

var keywords = [
    "def",
    "loop",
    "print"
]

type
    TokenType = enum
        rootProgram,
        blockNodeDef,
        leftBracket,
        rightBracket,
        identifier,
        literal,
        stringLiteral,
        funcDef,
        varDef,
        loopDef,
        printDef,
    Token = object
        value: string
        tokenType: TokenType

var tokens: seq[Token]
var
    id = ""
    strLiteral = ""
    stringStack: seq[string]
    bracesStack: seq[string]
    flowerStack: seq[string]

proc debug(msg: string) =
    # echo "[debug]"&msg
    return

proc isKeyword(identifier: string): bool =
    for keywd in keywords:
        if identifier == keywd:
            return true
    return false

proc handleKeywordIdentifiers(identifier: string) =
    case identifier:
        of "loop":
            tokens.add(
                Token(
                    value: id,
                    tokenType: loopDef
                )
            )
        of "print":
            tokens.add(
                Token(
                    value: id,
                    tokenType: printDef
                )
            )
        of "def":
            tokens.add(
                Token(
                    value: id,
                    tokenType: funcDef
                )
            )
        else:
            return

proc characterAnalyse(line: string) =
    if len(line) == 0:
        return

    for i, chr in line:
        debug $chr
        case chr:
            of '"':
                debug "found string declaration"
                if stringStack.len > 0:
                    discard stringStack.pop()
                    tokens.add(
                        Token(
                            value: strLiteral,
                            tokenType: stringLiteral
                        )
                    )
                    strLiteral = ""
                else:
                    stringStack.add($chr)
            of '(':
                debug "adding to braces"
                bracesStack.add($chr)
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: leftBracket
                    )
                )

            of '{':
                debug "adding flower brace"
                flowerStack.add($chr)
                debug $flowerStack.len
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: leftBracket
                    )
                )

            of ')':
                debug "found ending brace,popping"
                if bracesStack.len == 0:
                    quit "error at" & line
                discard bracesStack.pop()
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: rightBracket
                    )
                )

            of '}':
                debug "found ending flower brace,popping"
                debug $flowerStack
                if flowerStack.len == 0:
                    quit "error at" & line
                discard flowerStack.pop()
                tokens.add(
                    Token(
                        value: $chr,
                        tokenType: rightBracket
                    )
                )
            of ':':
                if i+1 <= line.len-1 and line[i+1] == '=':
                    tokens.add(
                        Token(
                            value: ":=",
                            tokenType: varDef
                        )
                    )
            else:

                # possibly inside a string, let it take up
                # everything till the end of string
                if stringStack.len > 0:
                    strLiteral = strLiteral & $chr
                    debug "strLiteral:" & strLiteral

                # if not then check if it's a variable that's
                # being used, mark as an identifier
                elif match($chr, variableCharacters):
                    id = id & chr
                    if i+1 > line.len-1:
                        if isKeyword(id):
                            handleKeywordIdentifiers(id)
                            id = ""
                        else:
                            tokens.add(
                                Token(
                                    value: id,
                                    tokenType: identifier
                                )
                            )
                            id = ""
                    elif not match($line[i+1], variableCharacters):
                        if isKeyword(id):
                            handleKeywordIdentifiers(id)
                            id = ""
                        else:
                            tokens.add(
                                Token(
                                    value: id,
                                    tokenType: identifier
                                )
                            )
                            id = ""


type
    NodeRef = ref Node
    Node = object
        value: string
        valueType: string
        nodeType: TokenType
        params: seq[NodeRef]
        children: seq[NodeRef]

proc printAST(ast: NodeRef) =
    echo %*ast    

proc constructAST() =
    var program: NodeRef
    new(program)
    program.nodeType = rootProgram

    var nodeStack:seq[NodeRef]
    var paramMode = false 
    nodeStack.add(program)

    for i, tok in tokens:
        case tok.tokenType:
            of loopDef:
                var loopNode: NodeRef
                new(loopNode)
                loopNode.nodeType = loopDef
                nodeStack[nodeStack.high].children.add(loopNode)
                nodeStack.add(loopNode)
            of printDef:
                var printNode: NodeRef
                new(printNode)
                printNode.nodeType = printDef
                nodeStack[nodeStack.high].children.add(printNode)
                nodeStack.add(printNode)
            of leftBracket:
                if tok.value == "(":
                    paramMode = true
                elif tok.value == "{":
                    var blockNode: NodeRef
                    new(blockNode)
                    blockNode.nodeType = blockNodeDef
                    nodeStack[nodeStack.high].children.add(blockNode)
                    nodeStack.add(blockNode)
            of rightBracket:
                if tok.value == ")":
                    paramMode = false
                if tok.value == "}":
                    discard nodeStack.pop()
                discard nodeStack.pop()

            of identifier, stringLiteral:
                var idNode: NodeRef
                new(idNode)

                idNode.nodeType = tok.tokenType

                if tok.tokenType == stringLiteral:
                    idNode.value = tok.value
                    idNode.valueType = "string"

                if paramMode:
                    nodeStack[nodeStack.high].params.add(idNode)
                else:
                    nodeStack[nodeStack.high].children.add(idNode)
            else:
                continue
                # echo "dancing"

    printAST(program)


proc main() =
    var
        fname = "./example/main.mole"

    for line in lines fname:
        if line.isEmptyOrWhitespace():
            continue

        if line.startsWith("--"):
            # ignore comment parsing for now
            continue
        else:
            characterAnalyse(line)

    constructAST()

main()
