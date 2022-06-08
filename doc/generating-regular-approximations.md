# Generating regular expressions using Gingersnap

2021-11-19, copy edits 2021-12-22

For regular approximations, the following two stylesheets are your
friends.

* `R0-superset`
* `rk-subset`

Their pipelines are described below, if you need a slightly modified
workflow.

If you have a more general interest, or just want to see how things
work, the examples below may not help much.  Sorry.  In any case, take
what's here with a grain of salt.  The library is not finished, and
working to improve it is more interesting than documenting its current
state.  It's never a good time to write out examples for this section.
What's here was cobbled together while I was trying to understand the
library, coming back to it after months of not using it.  (Maybe there
is a good time, after all: the moment when you wish you had some
documentation explaining whatever it is you now want to know.)


### Generating a subset for depth k

The `rk-subset` stylesheet uses a two-stage pipeline:

````
    <grammar-pipeline>

      <desc>
        <p>This pipeline takes an ixml grammar and produces an r_k
        subset grammar.</p>
        <p>Two steps are required:  first, parent/child annotation,
        and then the generation of the subset.</p>
      </desc>

      <annotate-pc/>
      <rk-subset k="{$k}"/>

    </grammar-pipeline>
````

The output is a version of the original grammar which effectively
limits stack depth to *k* (using affixes to the original nonterminals
to allow the attentive reader to see what is going on).

### Generating the O0 superset and other supersets

The `R0-superset`stylesheet generates the 0-depth superset with this
embedded pipeline:

````
    <grammar-pipeline>

      <desc>
        <p>This pipeline takes an ixml grammar and produces an R_0
        superset grammar, in the form of a stack-augmented
        pseudo-regular grammar showing the recursive transition
        network for the input grammar.</p>
        <p>...</p>
      </desc>

      <annotate-pc save="temp.r0.pc.xml">
        <desc>
          <p>Parent/child annotation is a prerequisite for
          Gluschkov annotation.</p>
        </desc>
      </annotate-pc>

      <annotate-gl save="temp.r0.gl.xml">
        <desc>
          <p>Gluschkov annotation is a prerequisite for
          making the RTN.</p>
        </desc>
      </annotate-gl>

      <make-rtn non-fissile="{if (empty($pseudo-terminals))
                             then '#none'
                             else $pseudo-terminals}"
                start="{$start}"
                linkage="#none"
                keep-non-fissiles="#yes"
                save="temp.r0.rtn.xml"
                >
        <desc>
          <p>Build the RTN, using all recursive nonterminals
          and providing no external linkage.</p>
        </desc>
      </make-rtn>
      <!--
      <expand-references nonterminal="{$pseudo-terminals}"/>      
      -->
    </grammar-pipeline>    
````

As may be seen, the key steps are Gluschkov annotation and RTN
generation, and we have some choice about what nonterminals to treat
as pseudo-terminals and not expand. 

To make O*k* supersets for *k* greater than zero,

* Generate the O0 superset.

* Generate the u*k* subset.

* Knit the two together: at the places where the u*k* subset has
  references to the empty set, replace those references with
  references to the O0 superset.
