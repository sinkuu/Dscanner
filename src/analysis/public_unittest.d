module analysis.public_unittest;


import std.algorithm;
import std.d.ast;
import std.d.lexer;
import std.string;
import std.typecons;
import analysis.base;


final class PublicUnittestCheck : BaseAnalyzer
{
	alias visit = BaseAnalyzer.visit;

	this(string fileName)
	{
		super(fileName);
	}

	private IdType protection = tok!"public";
	private bool inUnittestVersion;

	override void visit(const AttributeDeclaration attrdec)
	{
		if (attrdec.attribute.attribute.among(tok!"private", tok!"package", tok!"public"))
		{
			protection = attrdec.attribute.attribute;
		}
	}

	override void visit(const ConditionalDeclaration cond)
	{
		if (cond.compileCondition.versionCondition !is null)
		{
			if (cond.compileCondition.versionCondition.token == tok!"unittest")
			{
				bool orig = inUnittestVersion;
				auto origp = protection;

				inUnittestVersion = true;
				foreach (d; cond.trueDeclarations) visit(d);

				protection = origp;

				inUnittestVersion = false;
				foreach (d; cond.falseDeclarations) visit(d);

				protection = origp;
				inUnittestVersion = orig;
				return;
			}
		}

		cond.accept(this);
	}

	override void visit(const Declaration decl)
	{
		Nullable!IdType orig = protection;

		foreach (a; decl.attributes)
		{
			if (a.attribute.among(tok!"private", tok!"package", tok!"public"))
			{
				protection = a.attribute;
			}
		}

		decl.accept(this);

		if (decl.attributeDeclaration is null) protection = orig;
	}

	override void visit(const VariableDeclaration var)
	{
		foreach (a; var.attributes)
		{
			if (a.attribute.among(tok!"private", tok!"package")) return;
		}

		if (inUnittestVersion && inPublic && var.comment is null)
		{
			if (var.autoDeclaration !is null)
			{
				auto d = var.autoDeclaration;
				addErrorMessage(d.identifiers[0].line, d.identifiers[0].column,
						"dscanner.confusing.public_unittest",
						format("Public and version(unittest) variable '%s' is confusing.",
							d.identifiers[0].text));
			}

			foreach (d; var.declarators)
			{
				addErrorMessage(d.name.line, d.name.column,
						"dscanner.confusing.public_unittest",
						format("Public and version(unittest) variable '%s' is confusing.", d.name.text));
			}
		}
	}

	override void visit(const FunctionBody fb) { }
	override void visit(const Unittest u) { }

	mixin visitDecl!ClassDeclaration;
	mixin visitDecl!StructDeclaration;
	mixin visitDecl!InterfaceDeclaration;
	mixin visitDecl!UnionDeclaration;
	mixin visitDecl!FunctionDeclaration;
	mixin visitDecl!TemplateDeclaration;

	override void visit(const AliasDeclaration ad)
	{
		if (inUnittestVersion && inPublic && ad.comment is null)
		{
			if (ad.initializers.length > 0)
			{
				foreach (i; ad.initializers)
				{
					addErrorMessage(i.name.line, i.name.column, "dscanner.confusing.public_unittest",
							format("Public and version(unittest) declaration '%s' is confusing.",
								i.name.text));
				}
			}
			else
			{
				import std.array : array;
				import std.string : join;

				foreach (i; ad.identifierList.identifiers)
				{
					addErrorMessage(i.line,
							i.column, "dscanner.confusing.public_unittest",
							format("Public and version(unittest) declaration '%s' is confusing.", i.text));
				}
			}
		}
	}


	private:

	@property bool inPublic()
	{
		return protection == tok!"public";
	}

	mixin template visitDecl(T)
	{
		override void visit(const T decl)
		{
			import std.traits : hasMember;
			bool public_ = inPublic;

			static if (hasMember!(T, "attributes"))
			{
				foreach (a; decl.attributes)
				{
					if (a.attribute.among(tok!"private", tok!"package")) return;
					if (a.attribute == tok!"public") public_ = true;
				}
			}

			if (inUnittestVersion && public_ && decl.comment is null)
			{
				addErrorMessage(decl.name.line, decl.name.column, "dscanner.confusing.public_unittest",
						format("Public and version(unittest) declaration '%s' is confusing.",
							decl.name.text));
			}
		}
	}
}
