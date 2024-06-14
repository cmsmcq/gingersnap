(: example grammar for recursive-descent parsing :)

declare function local:sym($E0 as element(env)) as xs:string {
  $E0/sym/string()
};

declare function local:next($E0 as element(env)) as element(env) {
  let $p := $E0/pos/number() + 1
  return element env {
    element sym { substring($E0/input, $p, 1) },
    element pos { $p },
    $E0/input,
    $E0/len
  }
};

declare function local:error(
  $E0 as element(env), 
  $s as xs:string,
  $misc as item()*
) as element(env) {
  element env {
    element error { $s },
    $E0/*,
    $misc
  }
};

(: S = A, (B|C). :)
declare function local:S($E0 as element(env)) as item()+ {
  let $R1 := local:A($E0),
      $R2 := (  let $sym := local:sym($R1[1])
                return if ($sym = ('b', 'B', 'D'))
                       then local:B($R1[1])
                       else if (string-length($sym) eq 0)
                       then local:B($R1[1])
                       else if ($sym = ('c'))
                       then local:C($R1[1])
                       else <error/>
             )
  return if (($R1[1], $R2[1])/error)
         then local:error($E0, 'could not read S', ($R1, $R2))
         else ($R1[1], element S { tail($R1), tail($R2) } )
};

(: A = ('a'+) ** '.'.  :)
declare function local:A($E0 as element(env)) as item()+ {
  let $R1 := local:seqsep_a_dot($E0)
  return ($R1[1], element A { tail($R1) } )
};

declare function local:seqsep_a_dot($E0 as element(env)) as item()+ {
  if (local:sym($E0) = ('a'))
  then let $R1 := local:plus_a($E0),
           $R2 := ( if (local:sym($R1[1]) = '.')
                    then let $R3 := (local:next($R1[1]), text { '.' }),
                             $R4 := local:seqsep_a_dot($R3[1]) 
                         return ($R4[1], tail($R3), tail($R4))
                    else $R1[1]
           )
       return ($R2[1], tail($R1), tail($R2))
  else $E0
};

declare function local:plus_a($E0 as element(env)) as item()+ {
  if (local:sym($E0) = 'a')
  then local:star_a($E0)
  else local:error($E0, "'a' required but not found", ())
};

declare function local:star_a($E0 as element(env)) as item()+ {
  if (local:sym($E0) = ('a'))
  then let $R1 := (local:next($E0), text { 'a' }),
           $R2 := local:star_a($R1[1])
       return ($R2[1], tail($R1), tail($R2))
  else $E0
};

(: B = (['Bb']*, D. :)
declare function local:B($E0 as element(env)) as item()+ {
  let $R1 := local:star_Bb($E0),
      $R2 := (if (local:sym($R1[1]) = 'D')
              then (local:next($R1[1]), text{'D'})
              else $R1[1]
             )
  return ($R2[1], element B { tail($R1), tail($R2) })
};

declare function local:star_Bb($E0 as element(env)) as item()+ {
  if (local:sym($E0) = ('B', 'b'))
  then let $R1 := (local:next($E0), text { local:sym($E0) }),
           $R2 := local:star_Bb($R1[1])
       return ($R2[1], tail($R1), tail($R2))
  else $E0
};

(: C = 'c' ++ '-'. :)
declare function local:C($E0 as element(env)) as item()+ {
  if (local:sym($E0) = ('c'))
  then let $R1 := local:seqsep_c_hyphen($E0)
       return ($R1[1], element C { tail($R1) } )
  else local:error($E0, "expected at least one 'c'", ())
};

declare function local:seqsep_c_hyphen($E0 as element(env)) as item()+ {
  if (local:sym($E0) = ('c'))
  then let $R1 := ( local:next($E0), text { 'c' } ),
           $R2 := if (local:sym($R1[1]) = ('-'))
                  then let $R3 := ( local:next($R1[1]), text { '-' }), 
                           $R4 := local:seqsep_c_hyphen($R3[1])
                       return ($R4[1], tail($R3), tail($R4))
                  else $R1[1]
     return ($R2[1], tail($R1), tail($R2))
else $E0
};


(: D = #44? :)
declare function local:D($E0 as element(env)) as item()+ {
  let $R1 := if (local:sym($E0) = '&#x44;')
             then (local:next($E0), '&#x44;')
             else $E0
  return ($R1[1], element D { tail($R1) } )
};

let $strings := <strings>
      <string></string>
      <string>aD</string>
      <string>aaaaa.aB</string>
      <string>a.a.a.aa.aBbBbBbBBBBbbbbD</string>
      <string>aaa.aaac</string>
      <string>c-c-c-c-c-c-c</string>>
      <string>abc</string>
    </strings>
return <parse-trees>{
  for $s in $strings/string/string()
  let $E0 := element env {
    element sym { substring($s,1,1) },
    element input { $s },
    element pos { 1 },
    element len { string-length($s) }
  }
  let $R1 := local:S($E0)
  return <parse-tree input="{$s}">{tail($R1)}</parse-tree>
 
}</parse-trees>