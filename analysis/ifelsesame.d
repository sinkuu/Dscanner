//          Copyright Brian Schott (Sir Alaran) 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module analysis.ifelsesame;

import std.d.ast;
import std.d.lexer;
import analysis.base;

/**
 * Checks for if statements whose "then" block is the same as the "else" block
 */
class IfElseSameCheck : BaseAnalyzer
{
	alias visit = BaseAnalyzer.visit;

	this(string fileName)
	{
		super(fileName);
	}

	override void visit(const IfStatement ifStatement)
	{
		if (ifStatement.thenStatement == ifStatement.elseStatement)
			addErrorMessage(ifStatement.line, ifStatement.column,
				"\"Else\" branch is identical to \"Then\" branch.");
		ifStatement.accept(this);
	}

	override void visit(const AssignExpression assignExpression)
	{
		const AssignExpression e = cast(const AssignExpression) assignExpression.assignExpression;
		if (e !is null && assignExpression.operator == tok!"="
			&& e.ternaryExpression == assignExpression.ternaryExpression)
		{
			addErrorMessage(assignExpression.line, assignExpression.column,
				"Left side of assignment operatior is identical to the right side");
		}
		assignExpression.accept(this);
	}
}