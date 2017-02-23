package ;

class Node
{
    public var value:String;
    public var children:Array<Node> = [];
    public var parent:Node;

    public function new(value:String)
    {
        this.value = value;
    }

    public function hasChildren():Bool
    {
        return this.children.length != 0;
    }

    public function isLastChild():Bool
    {
        if (this.parent != null)
        {
            return this.parent.children[this.parent.children.length - 1] == this;
        }
        return true;
    }
}

class IdentNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

class IntNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

class AssignNode extends Node
{
    public var left:Node;
    public var right:Node;
    override public function new(value:String, left:Node, right:Node)
    {
        super(value);
        this.children.push(left);
        this.children.push(right);
        this.left = this.children[0];
        this.right = this.children[1];
        this.left.parent = this;
        this.right.parent = this;   
    }
}

class PrefixNode extends Node
{
    public var child:Node;
    override public function new(value:String, child:Node)
    {
        super(value);
        this.children.push(child);
        this.child = this.children[0];
        this.child.parent = this;
    }
}

class InfixNode extends Node
{
    public var left:Node;
    public var right:Node;
    override public function new(value:String, left:Node, right:Node)
    {
        super(value);
        this.children.push(left);
        this.children.push(right);
        this.left = this.children[0];
        this.right = this.children[1];
        this.left.parent = this;
        this.right.parent = this;        
    }
}

class PostfixNode extends Node
{
    public var child:Node;
    override public function new(value:String, child:Node)
    {
        super(value);
        this.children.push(child);
        this.child = this.children[0];
        this.child.parent = this;
    }
}

class CallNode extends Node
{
    public var name:Node;
    override public function new(name:Node, args:Array<Node>)
    {
        super(name.value);
        children.push(name);
        name.parent = this;
        for (arg in args)
        {
            children.push(arg);
            arg.parent = this;
        }
    }
}

class BlockNode extends Node
{
    override public function new(statements:Array<Node>)
    {
        super("BLOCK");
        for (statement in statements)
        {
            children.push(statement);
            statement.parent = this;
        }

    }
}