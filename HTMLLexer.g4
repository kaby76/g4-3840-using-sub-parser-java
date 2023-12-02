/*
 [The "BSD licence"]
 Copyright (c) 2013 Tom Everett
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


lexer grammar HTMLLexer;

tokens { SCRIPT_END, STYLE_END }

@lexer::header {
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.LinkedList;
}

@lexer::members {
private LinkedList<Token> queue = new LinkedList<>();

@Override public Token nextToken()
{
    if (!queue.isEmpty())
    {
        return queue.poll();
    }
    Token next = super.nextToken();
    return next;
}

private CommonToken createToken(int type, String text)
{
    int stop = getCharIndex() - 1;
    int start = text.length() == 0 ? stop : stop - text.length() + 1;
    return new CommonToken(type, text);
}

}


HTML_COMMENT: '<!--' .*? '-->';

HTML_CONDITIONAL_COMMENT: '<![' .*? ']>';

XML: '<?xml' .*? '>';

CDATA: '<![CDATA[' .*? ']]>';

DTD: '<!' .*? '>';

SCRIPTLET: '<?' .*? '?>' | '<%' .*? '%>';

SEA_WS: (' ' | '\t' | '\r'? '\n')+;

SCRIPT_OPEN: '<script' .*? '>' -> pushMode(SCRIPT);

STYLE_OPEN: '<style' .*? '>' -> pushMode(STYLE);

TAG_OPEN: '<' -> pushMode(TAG);

HTML_TEXT: ~'<'+;

// tag declarations

mode TAG;

TAG_CLOSE: '>' -> popMode;

TAG_SLASH_CLOSE: '/>' -> popMode;

TAG_SLASH: '/';

// lexing mode for attribute values

TAG_EQUALS: '=' -> pushMode(ATTVALUE);

TAG_NAME: TAG_NameStartChar TAG_NameChar*;

TAG_WHITESPACE: [ \t\r\n] -> channel(HIDDEN);

fragment HEXDIGIT: [a-fA-F0-9];

fragment DIGIT: [0-9];

fragment TAG_NameChar:
	TAG_NameStartChar
	| '-'
	| '_'
	| '.'
	| DIGIT
	| '\u00B7'
	| '\u0300' ..'\u036F'
	| '\u203F' ..'\u2040'
;

fragment TAG_NameStartChar:
	[:a-zA-Z]
	| '\u2070' ..'\u218F'
	| '\u2C00' ..'\u2FEF'
	| '\u3001' ..'\uD7FF'
	| '\uF900' ..'\uFDCF'
	| '\uFDF0' ..'\uFFFD'
;

// <scripts>

mode SCRIPT;

SCRIPT_BODY: .*? '</script>' {
var start = this._tokenStartCharIndex;
var end = this.getCharIndex();
var len = end - start;
var text = this.getText().substring(this.getText().length()-len);
text = text.substring(0, text.length() - "</script>".length());
var str = CharStreams.fromString(text);
var lexer = new JavaScriptLexer(str);
for (int i = 0; ; ++i)
{
    var ro_token = lexer.nextToken();
    var token = (CommonToken)ro_token;
    token.setTokenIndex(i);
    if (token.getType() == Token.EOF)
    {
        token = this.createToken(SCRIPT_END, "</script>");
        queue.addLast(token);
        break;
    }
    token.setChannel(2);
    queue.addLast(token);
}
} -> skip, popMode;

SCRIPT_SHORT_BODY: .*? '</>' {
var start = this._tokenStartCharIndex;
var end = this.getCharIndex();
var len = end - start;
var text = this.getText().substring(this.getText().length()-len);
text = text.substring(0, text.length() - "</>".length());
var str = CharStreams.fromString(text);
var lexer = new JavaScriptLexer(str);
for (int i = 0; ; ++i)
{
    var ro_token = lexer.nextToken();
    var token = (CommonToken)ro_token;
    token.setTokenIndex(i);
    if (token.getType() == Token.EOF)
    {
        token = this.createToken(SCRIPT_END, "</>");
        queue.addLast(token);
        break;
    }
    token.setChannel(2);
    queue.addLast(token);
}
} -> skip, popMode;

// <styles>

mode STYLE;

STYLE_BODY: .*? '</style>' {
var start = this._tokenStartCharIndex;
var end = this.getCharIndex();
var len = end - start;
var text = this.getText().substring(this.getText().length()-len);
text = text.substring(0, text.length() - "</style>".length());
var str = CharStreams.fromString(text);
var lexer = new JavaScriptLexer(str);
for (int i = 0; ; ++i)
{
    var ro_token = lexer.nextToken();
    var token = (CommonToken)ro_token;
    token.setTokenIndex(i);
    if (token.getType() == Token.EOF)
    {
        token = this.createToken(STYLE_END, "</style>");
        queue.addLast(token);
        break;
    }
    token.setChannel(3);
    queue.addLast(token);
}
} -> skip, popMode;

STYLE_SHORT_BODY: .*? '</>' {
var start = this._tokenStartCharIndex;
var end = this.getCharIndex();
var len = end - start;
var text = this.getText().substring(this.getText().length()-len);
text = text.substring(0, text.length() - "</>".length());
var str = CharStreams.fromString(text);
var lexer = new JavaScriptLexer(str);
for (int i = 0; ; ++i)
{
    var ro_token = lexer.nextToken();
    var token = (CommonToken)ro_token;
    token.setTokenIndex(i);
    if (token.getType() == Token.EOF)
    {
        token = this.createToken(STYLE_END, "</>");
        queue.addLast(token);
        break;
    }
    token.setChannel(3);
    queue.addLast(token);
}
} -> skip, popMode;

// attribute values

mode ATTVALUE;

// an attribute value may have spaces b/t the '=' and the value
ATTVALUE_VALUE: ' '* ATTRIBUTE -> popMode;

ATTRIBUTE:
	DOUBLE_QUOTE_STRING
	| SINGLE_QUOTE_STRING
	| ATTCHARS
	| HEXCHARS
	| DECCHARS
;

fragment ATTCHARS: ATTCHAR+ ' '?;

fragment ATTCHAR:
	'-'
	| '_'
	| '.'
	| '/'
	| '+'
	| ','
	| '?'
	| '='
	| ':'
	| ';'
	| '#'
	| [0-9a-zA-Z]
;

fragment HEXCHARS: '#' [0-9a-fA-F]+;

fragment DECCHARS: [0-9]+ '%'?;

fragment DOUBLE_QUOTE_STRING: '"' ~[<"]* '"';

fragment SINGLE_QUOTE_STRING: '\'' ~[<']* '\'';