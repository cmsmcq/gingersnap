# gingersnap
Tools for grammars in ixml

This is a small library of XSLT modules which read and (mostly) write
ixml (invisible XML) grammars.  (For more on invisible XML, see
https://invisiblexml.org and material linked from there.)  The name
*Gingersnap* is suggested by the *g* of *grammars* and the *i* of
*ixml*.

The immediate impetus for Gingersnap is the desire to create test
cases for ixml grammars.  That is, given an ixml grammar *G*, I would
like tools to generate a set of positive test cases (strings or files
which are sentences in *L(G)*, the language defined by *G*) and a set
of negative test cases (strings or files which are *not* in *L(G)* and
should not be accepted by software whose inputs are defined or
partially defined by *G*).

Over time, the focus of the library is expected to broaden to include
grammar-related tools with other applications.

The default license is GPL 3.0; other license terms may be available.

