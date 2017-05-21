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

    /**
     *  Check if this node has children.
     */
    public function hasChildren():Bool
    {
        return this.children.length != 0;
    }
    
    /**
     *  Check if this node is the last child of its parent.
     *  @return Bool
     */
    public function isLastChild():Bool
    {
        if (this.parent != null)
        {
            return this.parent.children[this.parent.children.length - 1] == this;
        }
        return true;
    }
}

/**
 *  Represents the program itself, containing all the top level children.
 */
class ProgramNode extends Node
{
    /**
     *  Create a new ProgramNode.
     *  @param nodes - An array of child nodes at the program level.
     */
    override public function new(nodes:Array<Node>)
    {
        super("PROGRAM");
        for (node in nodes)
        {
            children.push(node);
            node.parent = this;
        }
    }
}

/**
 *  Represents an identifier.
 */
class IdentNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

/**
 *  Represents an integer literal.
 */
class IntNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

/**
 *  Represents a string literal.
 */
class StringNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

/**
 *  Represents a boolean literal.
 */
class BooleanNode extends Node
{
    override public function new(value:String)
    {
        super(value);
    }
}

/**
 *  Represents a variable assignment.
 */
class AssignNode extends Node
{
    /**
     *  Left-hand side of the assignment, should be an identifier.
     */
    public var left:Node;
    
    /**
     *  Right-hand side of the assignment, may be a range of types.
     */
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

/**
 *  Represents a function definition.
 */
class FunctionNode extends Node
{
    /**
     *  An identifier; the name of the function.
     */
    public var name:Node;

    /**
     *  A list of arguments to the function.
     */
    public var args:Array<Node> = [];

    /**
     *  The body of the function, an array of child nodes.
     */
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

/**
 *  Represents a prefix operator.
 */
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

/**
 *  Represents an infix operator.
 */
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

/**
 *  Represents a postfix operator.
 */
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

/**
 *  Represents a function call.
 */
class CallNode extends Node
{
    /**
     *  Identifier of the function to be called.
     */
    public var name:Node;

    /**
     *  List of arguments to pass to the function.
     */
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

/**
 *  Represents a block of code.
 */
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

/**
 *  Represents a while loop.
 */
class WhileNode extends Node
{
    /**
     *  The condition of the while loop, an expression to be evaluated
     *  every time the while loop runs.
     */
    public var condition:Node;

    /**
     * The body of the while loop, an array of child nodes. 
     */
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

/**
 *  Represents an if statement.
 */
class IfNode extends Node
{
    /**
     *  The condition of the if statement.
     */
    public var condition:Node;

    /**
     *  The body of the if statement, an array of child nodes.
     */
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

/**
 *  A break statement. Prematurely exits a loop.
 */
class BreakNode extends Node
{
    override public function new()
    {
        super("break");
    }
}