# Introducing the xml-registry gem

## Installation

`gem install xml-registry`

## Example

    require 'xml-registry' 

    s =<<REG
    [app/app1]
    "admin"="jrobertson"
    "pin-no"="1234"

    [app/app2]
    "admin"="dsmith"
    "pin-no"="4321"
    REG

    reg = XMLRegistry.new 
    reg.set_key 'app/whiteboard/colour', 'red' 
    reg.to_xml 
    #=> "red" 

    reg.import s 
    reg.to_xml

output: 

    <root>
      <system/>
      <app>
        <whiteboard>
          <colour>red</colour>
        </whiteboard>
        <app1>
          <admin>jrobertson</admin>
          <pin-no>1234</pin-no>
        </app1>
        <app2>
          <admin>dsmith</admin>
          <pin-no>4321</pin-no>
        </app2>
      </app>
    </root>

    puts reg.export 

output: 

<pre>
[app/whiteboard]
"colour"="red"

[app/app1]
"admin"="jrobertson"
"pin-no"="1234"

[app/app2]
"admin"="dsmith"
"pin-no"="4321"
</pre>
