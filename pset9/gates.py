n = int(raw_input())

for i in range(n):
    inputs = raw_input()
    inputs = [int(n) for n in inputs.split(',')]
    a, b, c, d, e = inputs
    anb = a and b
    bnc = b and c
    tanb = not anb
    tbnc = not bnc
    tanbotbnc = tanb or tbnc
    ttanbotbnc = not tanbotbnc
    end = e and d
    tend = not end
    tendod = tend or d
    last = ttanbotbnc and tendod
    print inputs
    print "  a & b:  %d" % anb
    print "!(a & b): %d" % tanb
    print "  b & c:  %d" % bnc
    print "!(b & c): %d" % tbnc
    print "  !(a & b) | !(b & c):  %d" % tanbotbnc
    print "!(!(a & b) | !(b & c)): %d" % ttanbotbnc
    print "  e & d:  %d" % end
    print "!(e & d): %d" % tend
    print "!(e & d) | d: %d" % tendod
    print "(!(!(a & b) | !(b & c)) & (!(e & d) | d)): %d" % last
    print ~(~(a & b) | ~(b & c)) & (~(e & d) | d)
