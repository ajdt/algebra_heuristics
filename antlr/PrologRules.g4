grammar PrologRules;

prologrule  :           predicate   ':-' predlist  '.';
predicate   :           atom '(' args ')' | atom ;
predlist    :           predicate ',' predlist | predicate ;
args        :           atom | atom ',' args ;
atom        :           WORD ;

WORD        :   [_a-zA-Z][_a-zA-Z0-9]* ;

