grammar PrologRules;

prologcode  :           prologthing (prologthing)* ;
prologthing :           somerule | fact | constraint ;
fact        :           predicate '.' ;
constraint  :           ':-' rulebody '.' ;
somerule    :           prologrule | guessrule ;
prologrule  :           predicate   ':-' rulebody  '.';
guessrule   :           NUMBER? '{' predicate (':' rulebody)? '}' NUMBER? ':-' rulebody '.';   // will be ignored
predcount   :           atom? '{' predicate (':' rulebody)? '}' atom? ; // bounds can be variables too so just use atoms
predicate   :           identifier '(' args ')' | identifier ;
rulebody    :           condition | condition ',' rulebody ;
condition   :           negpred | predicate | comparator | predcount ;
negpred     :           'not' predicate ;   // defined separately so we can remember that predicate was negated
comparator  :           atom RELOPERATOR mathexpr ;    // note: we assume operator only compares simple types
mathexpr    :           OPERATOR mathexpr | atom OPERATOR mathexpr | atom | predicate ;
args        :           onearg (',' onearg)* ;
onearg      :           atom | predicate ;

atom        :           identifier | NUMBER ;
identifier  :           WORD ;

NUMBER      :   [0-9]+ ;
RELOPERATOR :   '=' | '<' | '>' | '>=' | '<=' | '!=' ;
OPERATOR    :   '+' | '-' | '*' | '**' | '/' ;
WORD        :   [_a-zA-Z][_a-zA-Z0-9]* ;
COMMENT     :   '%'(.)*'\n' -> skip ;
WS          :   [\n\r\t' ']+ -> skip ;

/*
grammar PrologRules;

prologrule  returns [rule_data]
    :           predicate   ':-' predlist  '.'
                { $rule_data = ($predicate.text, $predlist.list_of_preds) };
predicate   returns [text]
    :           atom '(' args ')' {$text = ($atom.name, $args.vallist)} | atom {$text = ($atom.name, None) } ;
predlist    returns [list_of_preds]
    :           predicate ',' predlist {$list_of_preds = [$predicate.text] + $predlist.list_of_preds}
                | predicate {$list_of_preds = [$predicate.text] };
args        returns [vallist]       
    :           atom {$vallist = [$atom.name]} | atom ',' args {$vallist = [$atom.name] + $args.vallist};
atom        returns [name]
    :           WORD {$name = $WORD.text } ;

WORD        :   [_a-zA-Z][_a-zA-Z0-9]* ;
*/

