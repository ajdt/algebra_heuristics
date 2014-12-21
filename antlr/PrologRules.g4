grammar PrologRules;

prologrule  :           predicate   ':-' predlist  '.';
predicate   :           atom '(' args ')' | atom ;
predlist    :           predicate ',' predlist | predicate ;
args        :           atom (',' atom)* ;
atom        :           WORD ;

WORD        :   [_a-zA-Z][_a-zA-Z0-9]* ;

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

