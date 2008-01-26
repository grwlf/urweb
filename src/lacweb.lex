(* Copyright (c) 2008, Adam Chlipala
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - The names of contributors may not be used to endorse or promote products
 *   derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *)

(* Lexing info for Laconic/Web programs *)

type pos = int
type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type lexresult = (svalue,pos) Tokens.token

local
  val commentLevel = ref 0
  val commentPos = ref 0
in
  fun enterComment pos =
      (if !commentLevel = 0 then
           commentPos := pos
       else
           ();
       commentLevel := !commentLevel + 1)
    
  fun exitComment () =
      (ignore (commentLevel := !commentLevel - 1);
       !commentLevel = 0)

  fun eof () = 
    let 
      val pos = ErrorMsg.lastLineStart ()
    in
      if !commentLevel > 0 then
          ErrorMsg.errorAt' (!commentPos, !commentPos) "Unterminated comment"
      else
          ();
      Tokens.EOF (pos, pos) 
    end
end

%%
%header (functor LacwebLexFn(structure Tokens : Lacweb_TOKENS));
%full
%s COMMENT;

id = [a-z_][A-Za-z0-9_]*;
cid = [A-Z][A-Za-z0-9_]*;
ws = [\ \t\012];

%%

<INITIAL> \n          => (ErrorMsg.newline yypos;
                          continue ());
<COMMENT> \n          => (ErrorMsg.newline yypos;
                          continue ());

<INITIAL> {ws}+       => (lex ());

<INITIAL> "(*"        => (YYBEGIN COMMENT;
                          enterComment yypos;
                          continue ());
<INITIAL> "*)"        => (ErrorMsg.errorAt' (yypos, yypos) "Unbalanced comments";
			  continue ());

<COMMENT> "(*"        => (enterComment yypos;
                          continue ());
<COMMENT> "*)"        => (if exitComment () then YYBEGIN INITIAL else ();
			  continue ());

<INITIAL> "("         => (Tokens.LPAREN (yypos, yypos + size yytext));
<INITIAL> ")"         => (Tokens.RPAREN (yypos, yypos + size yytext));
<INITIAL> "["         => (Tokens.LBRACK (yypos, yypos + size yytext));
<INITIAL> "]"         => (Tokens.RBRACK (yypos, yypos + size yytext));
<INITIAL> "{"         => (Tokens.LBRACE (yypos, yypos + size yytext));
<INITIAL> "}"         => (Tokens.RBRACE (yypos, yypos + size yytext));

<INITIAL> "->"        => (Tokens.ARROW (yypos, yypos + size yytext));
<INITIAL> "=>"        => (Tokens.DARROW (yypos, yypos + size yytext));
<INITIAL> "++"        => (Tokens.PLUSPLUS (yypos, yypos + size yytext));

<INITIAL> "="         => (Tokens.EQ (yypos, yypos + size yytext));
<INITIAL> ","         => (Tokens.COMMA (yypos, yypos + size yytext));
<INITIAL> ":::"       => (Tokens.TCOLON (yypos, yypos + size yytext));
<INITIAL> "::"        => (Tokens.DCOLON (yypos, yypos + size yytext));
<INITIAL> ":"         => (Tokens.COLON (yypos, yypos + size yytext));
<INITIAL> "."         => (Tokens.DOT (yypos, yypos + size yytext));
<INITIAL> "$"         => (Tokens.DOLLAR (yypos, yypos + size yytext));
<INITIAL> "#"         => (Tokens.HASH (yypos, yypos + size yytext));

<INITIAL> "con"       => (Tokens.CON (yypos, yypos + size yytext));
<INITIAL> "type"      => (Tokens.LTYPE (yypos, yypos + size yytext));
<INITIAL> "fn"        => (Tokens.FN (yypos, yypos + size yytext));

<INITIAL> "Type"      => (Tokens.TYPE (yypos, yypos + size yytext));
<INITIAL> "Name"      => (Tokens.NAME (yypos, yypos + size yytext));

<INITIAL> {id}        => (Tokens.SYMBOL (yytext, yypos, yypos + size yytext));
<INITIAL> {cid}       => (Tokens.CSYMBOL (yytext, yypos, yypos + size yytext));

<COMMENT> .           => (continue());

<INITIAL> .           => (ErrorMsg.errorAt' (yypos, yypos)
                                            ("illegal character: \"" ^ yytext ^ "\"");
                          continue ());
