#!/bin/bash

# usage:
#   - unpack ocaml-4.00.1.tar.gz
#   - configure
#   - make world.opt
#   - cd ocaml-4.00.1/testsuite/tests/
#   - run this script

dirs=$(grep -v '#' <<EOF
#asmcomp
#backtrace
basic
#basic-float
basic-io
basic-io-2
#basic-manyargs
basic-more
#basic-multdef
#basic-private
#callback
#embedded
#gc-roots
letrec
###there is an issue with ocamlclean 2.0 running on bigarrays.byte (ocaml 4.00), looks like infinite loop in step2.compute_deps
###lib-bigarray
#lib-bigarray-2
lib-digest
#lib-dynlink-bytecode
#lib-dynlink-csharp
#lib-dynlink-native
lib-hashtbl
#lib-marshal
#lib-num
lib-num-2
lib-printf
lib-scanf
#lib-scanf-2
lib-set
lib-str
#lib-stream
#lib-systhreads
#lib-threads
misc
#misc-kb
misc-unsafe
#prim-revapply
#regression
#runtime-errors
#tool-lexyacc
#tool-ocaml
#tool-ocamldoc
#typing-fstclassmod
#typing-gadts
#typing-implicit_unpack
#typing-labels
#typing-misc
#typing-modules
#typing-modules-bugs
#typing-objects
#typing-objects-bugs
#typing-poly
#typing-poly-bugs
#typing-polyvariants-bugs
#typing-polyvariants-bugs-2
#typing-private
#typing-private-bugs
#typing-recmod
#typing-signatures
#typing-sigsubst
#typing-typeparam
#warnings
EOF
)

echo -n > tests.passed
echo -n > tests.failed

for d in $dirs; do
    for f in $d/*.ml; do
        t=${f/.ml/}
        fbase=$(basename $f)
        fbyte=${fbase/.ml/.ocmlcc-byte}
        fnative=${fbase/.ml/.ocmlcc-native}
        echo -n "testing $t ... "
        (
            cd $(dirname $f)
            ocamlc_opts=
            cc_opts=
            run_args=
            case $t in
                basic-io/wc)
                    run_args=wc.ml
                    ;;
                basic-io-2/io)
                    run_args=io.ml
                    ;;
                basic-more/*|lib-printf/*|lib-scanf/*|lib-stream/*)
                    ocamlc_opts='-I ../../lib ../../lib/testing.ml'
                    ;;
                lib-bigarray/*)
                    ocamlc_opts='-I ../../../otherlibs/bigarray bigarray.cma -I ../../../otherlibs/unix unix.cma'
                    cc_opts='-verbose -stat -k -ccopts ../../../otherlibs/bigarray/libbigarray.a -ccopts ../../../otherlibs/unix/libunix.a'
                    ;;
                lib-num-2/*)
                    ocamlc_opts='-I ../../../otherlibs/num nums.cma'
                    cc_opts='-ccopts ../../../otherlibs/num/libnums.a'
                    run_args=1000
                    ;;
                lib-str/*)
                    ocamlc_opts='-I ../../../otherlibs/str str.cma'
                    cc_opts='-ccopts ../../../otherlibs/str/libcamlstr.a'
                    ;;
            esac
            [ -f $fbyte ] || ocamlc $ocamlc_opts -o $fbyte $fbase
            [ -f $fnative ] || ocamlcc $cc_opts -o $fnative $fbyte
            ./$fnative $run_args 2>&1 > ${fbase/.ml/.ocmlcc-result};
        ) > $t.log 2>&1 && {
            diff ${f/.ml/.reference} ${f/.ml/.ocmlcc-result} > /dev/null && {
                echo passed
                echo $t >> tests.passed
            }
        } || {
            echo FAILED
            echo $t >> tests.failed
        }
    done
done

wc -l tests.{passed,failed}
