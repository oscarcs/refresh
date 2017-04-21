package ;

typedef Symbol = {
    var type:String;
};

typedef Table = Map<String, Symbol>;

class Symtab 
{
    private var symtab:Array<Table>;

    public function new()
    {
        symtab = [];
        push();
    }

    /**
     *   Remove the last layer of the symbol table.
     */
    public function pop()
    {
        if (symtab.length > 0)
        {
            symtab.shift();
        }
    }

    /**
     *  Add a new layer into the symbol table.
     */
    public function push()
    {
        symtab.unshift(new Table());
    }

    /**
     *  Check if a certain symbol exists in the symbol table.
     *  @param name Name of the symbol
     */
    public function exists(name:String):Bool
    {
        return get(name) != null;
    }

    /**
     *  Get symbol from the symbol table.
     *  @param name Name of the symbol
     *  @return Symbol.
     */
    public function get(name:String):Symbol
    {
        for (table in symtab)
        {
            if (table.exists(name))
            {
                return table[name];
            }
        }
        return null;
    }

    /**
     *  Add an entry to the symbol table.
     *  @param name Name of the symbol.
     *  @param symbol Symbol.
     */
    public function put(name:String, symbol:Symbol)
    {
        symtab[0][name] = symbol;
    }

}