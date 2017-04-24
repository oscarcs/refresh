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

class RootNode extends Node
{
    override public function new(nodes:Array<Node>)
    {
        super("ROOT");
        for (node in nodes)
        {
            children.push(node);
            node.parent = this;
        }
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

class StringNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

class BooleanNode extends Node
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
        children.push(left);
        children.push(right);
        this.left = children[0];
        this.right = children[1];
        this.left.parent = this;
        this.right.parent = this;   
    }
}

class FunctionNode extends Node
{
    public var name:Node;
    public var args:Array<Node> = [];
    public var body:Array<Node> = [];
    override public function new(name:Node, args:Array<Node>, body:Array<Node>)
    {
        super(name.value);
        children.push(name);
        this.name = name;

        children = children.concat(args);
        children = children.concat(body);
        for (arg in args)
        {
            arg.parent = this;
            this.args.push(arg);
        }
        for (node in body)
        {
            node.parent = this;
            this.body.push(node);
        }
    }
}

class PrefixNode extends Node
{
    public var child:Node;
    override public function new(value:String, child:Node)
    {
        super(value);
        children.push(child);
        this.child = children[0];
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
        children.push(left);
        children.push(right);
        this.left = children[0];
        this.right = children[1];
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
        children.push(child);
        this.child = children[0];
        this.child.parent = this;
    }
}

class CallNode extends Node
{
    public var name:Node;
    public var args:Array<Node> = [];
    override public function new(name:Node, args:Array<Node>)
    {
        super(name.value);
        children.push(name);
        name.parent = this;
        this.name = name;
        for (arg in args)
        {
            children.push(arg);
            this.args.push(arg);
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

class WhileNode extends Node
{
    public var condition:Node;
    public var body:Array<Node> = [];
    override public function new(condition:Node, statements:Array<Node>)
    {
        super("WHILE");
        
        this.condition = condition;
        children.push(this.condition);
        this.condition.parent = this;

        for (statement in statements)
        {
            body.push(statement);
            children.push(statement);
            statement.parent = this;
        }
    }
}

class IfNode extends Node
{
    public var condition:Node;
    public var body:Array<Node> = [];
    override public function new(condition:Node, statements:Array<Node>)
    {
        super("IF");
        
        this.condition = condition;
        children.push(this.condition);
        this.condition.parent = this;

        for (statement in statements)
        {
            body.push(statement);
            children.push(statement);
            statement.parent = this;
        }
    }
}

class BreakNode extends Node
{
    override public function new()
    {
        super("break");
    }
}