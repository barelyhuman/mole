import std/[strutils]

type
    TokenType = enum
        leftBracket,
        rightBracket,
        varDefinition,
        comma,
        identifier,
        literal,
        stringLiteral,
        funcDef,
        loopDef,
        eof,
        newLine,
    Token = object
        value: string
        tokenType: TokenType

var tokens: seq[Token]

proc lexer(line: string) =
    var spaceParts = line.split()
    for part in spaceParts:
        if part == "(" or part == "{":
            tokens.add(
                Token(
                    value: part,
                    tokenType: leftBracket
                )
            )
        elif part == ")" or part == "}":
            tokens.add(
                Token(
                    value: part,
                    tokenType: rightBracket
                )
            )
        elif part == ":=":
            tokens.add(
                Token(
                    value: part,
                    tokenType: varDefinition
                )
            )
        elif part == "def":
            tokens.add(
                Token(
                    value: part,
                    tokenType: funcDef
                )
            )
        elif part == "loop":
            tokens.add(
                Token(
                    value: part,
                    tokenType: loopDef
                )
            )
        elif part.startsWith("\"") and part.endsWith("\""):
            tokens.add(
                Token(
                    value: part.replace("\"",""),
                    tokenType: stringLiteral
                )
            )
        else:
            tokens.add(
                Token(
                    value: part,
                    tokenType: identifier
                )
            )
    return


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
            lexer(line)

    echo tokens

main()
