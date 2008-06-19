Curly
-----

Curly is a wrapper for `Curl::Easy` from [Curb gem](http://curb.rubyforge.org/ "Curb - libcurl bindings for ruby"). It makes HTTP GET and POST even easier than `Curl::Easy`.

Examples
========

    # get a web page parsed with Hpricot
    Curly.get_document('http://www.google.com')
    # -> Hpricot::Doc instance
    
    # POST params as hash
    Curly.post('http://example.com/signup',
        :name => 'Mislav',
        :email => 'mislav.marohnic@gmail.com'
    )