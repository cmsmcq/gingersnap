(: Classcodes-to-ranges:  quick and dirty module to
   calculate ranges for class codes in Unicode.
   
   2020-12-22 : CMSMcQ : quick and dirty exploration
   
   To do:
   . Make rangify() return an inclusion element with a
     gt:ranges attribute listing all ranges, plus 
     actual range and literal elements for the component
     parts.
 :)

declare namespace 
  gt = "http://blackmesatech.com/2020/grammartools";

import module namespace 
  d2x = "http://blackmesatech.com/2019/iXML/d2x";

(: rangify($list, $current-range, $earlier-ranges) :)
declare function local:rangify(
  $li as xs:integer*,
  $lo as xs:integer?,
  $hi as xs:integer?,
  $acc as xs:integer*
) as xs:integer* {
  
  (: If list is empty, we are done. :)
  if (empty($li))
  then ($acc, $lo, $hi)
  
  (: If range is empty, we have no current range.
  Make one and recur. :)
  else if (empty(($lo, $hi)))
  then local:rangify(tail($li), head($li), head($li), $acc)
  
  (: Otherwise, we have a current range.  If the next
  number adjoins, increase $hi and recur.  If not, 
  close this range and send it to the accumulator,
  and recur :)
  else let $probe := head($li)
       return if ($probe eq $hi + 1)
              then local:rangify(tail($li), $lo, $probe, $acc)
              else local:rangify($li, (), (), ($acc, $lo, $hi))
};

declare function local:emit-range-elements(
  $lr as xs:integer*,
  $acc as element()*
) as element()+ {
  if (empty($lr))
  then $acc
  else 
  let $lo := $lr[1],
      $hi := $lr[2],
      $e := if ($lo eq $hi) 
            then <literal hex="{d2x:d2x($lo)}"
                          gt:ranges="{$lo, $hi}"/>
            else <range from="#{d2x:d2x($lo)}"
                        to="#{d2x:d2x($hi)}"
                        gt:ranges="{$lo, $hi}"/>
  return local:emit-range-elements(
             $lr[position() gt 2],
             ($acc, $e)
         )                 
};



(: XML character ranges:
  U+0020 - U+D7FF = 32 - 55295
  U+E000 - U+FFFD = 57344 - 65533
  U+10000 - U+10FFFF = 65536 - 1114111
:)

(: For now, let's stick to the basic multilingual plane :)
let $bmp := false()

for $classcode in ('Zs', 
                   'Ll', 'Lu', 'Lm', 'Lt', 'Lo', 
                   'Nd', 'Mn')
    (: let's do this for the classes used in ixml.ixml :)
let $re := '^\p{' || $classcode || '}$' 
let $lcp := for $cp in (32 to 55295, 57344 to 65533,
            if ($bmp) then () else 65537 to 1114111)
            return if (matches(codepoints-to-string($cp), $re))
                   then $cp  
                   else (),
    $lranges := local:rangify($lcp, (), (), ())
return <inclusion gt:code="{$classcode}" 
                  gt:regex="{$re}"
                  gt:ranges="{$lranges}">{
  local:emit-range-elements($lranges, ())
}</inclusion>