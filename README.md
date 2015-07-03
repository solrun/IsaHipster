# Hipster - theory exploration in Isabelle/HOL

Hipster is still under development, but feel free to play around with it! To
install Hipster, you first need Isabelle, QuickSpec and HipSpec.

Isabelle is available from: http://isabelle.in.tum.de/index.html. Hipster works
with [Isabelle 2014][Isa14], preferably in jEdit if you want nice syntactic sugar (soon
to be updated for [Isabelle 2015][Isa15]).

To install the appropriate [QuickSpec][QS]:

	git clone https://github.com/nick8325/quickspec.git
	cd quickspec
	cabal install

To install [HipSpec][HS], you will need to run the following commands:

    git clone https://github.com/danr/hipspec
    cd hipspec
    git checkout hipster
    cabal install 

Lastly, you will also have to compile the `HipSpecifyer`:

    cabal install hipspecifyer/
    
Finally, you should set the environment variable `$HIPSTER_HOME` (e.g. in your
`.profile` file) to the path for the IsaHipster directory you just cloned. If
you want to use Hipster from an Isabelle file, it needs to import the
`IsaHipster.thy` file (which essentially sets up Hipster) by including the
line:

```isabelle
imports "$HIPSTER_HOME/IsaHipster"
```
    
Now, you should be able to try Hipster. Start up Isabelle on for example
`Examples/TreeDemo.thy` and have a go.

_Disclaimer_: There are quite a few hacks around, and Hipster is not a polished
and finished product by any means. Let us know if you run into anything too odd,
and we'll try to fix it.


[QS]: https://github.com/nick8325/quickspec
[HS]: https://github.com/danr/hipspec
[Isa14]: http://isabelle.in.tum.de/download_past.html
[Isa15]: http://isabelle.in.tum.de/installation.html
