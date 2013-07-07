{
    r=strtonum($1)
    g=strtonum($2)
    b=strtonum($3)
    #print "rgb8 r=" r ", g=" g ", b=" b
    #printf ("rgb4 r=%x, g=%x, b=%x\n", r/16, g/16, b/16)
    printf ("%x%x%x\n", r/16, g/16, b/16)
}
