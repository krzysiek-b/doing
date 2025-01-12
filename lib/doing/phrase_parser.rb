# frozen_string_literal: true

require 'parslet'

module PhraseParser
  # This parser adds quoted phrases (using matched double quotes) in addition to
  # terms. This is done creating multiple types of clauses instead of just one.
  # A phrase clause generates an Elasticsearch match_phrase query.
  class QueryParser < Parslet::Parser
    CLAUSE_TYPES = %i[should must must_not].freeze

    rule(:term) { match('[^\s"]').repeat(1).as(:term) }
    rule(:quote) { str('"') }
    rule(:operator) { (str('+') | str('-')).as(:operator) }
    rule(:phrase) do
      (quote >> (term >> space.maybe).repeat >> quote).as(:phrase)
    end
    rule(:clause) { (operator.maybe >> (phrase | term)).as(:clause) }
    rule(:space)  { match('\s').repeat(1) }
    rule(:query) { (clause >> space.maybe).repeat.as(:query) }
    root(:query)
  end

  # Transforms the parsed query into a Query object
  class QueryTransformer < Parslet::Transform
    rule(clause: subtree(:clause)) do
      if clause[:term]
        TermClause.new(clause[:operator]&.to_s, clause[:term].to_s)
      elsif clause[:phrase]
        phrase = clause[:phrase].map { |p| p[:term].to_s }.join(' ')
        PhraseClause.new(clause[:operator]&.to_s, phrase)
      else
        raise "Unexpected clause type: '#{clause}'"
      end
    end
    rule(query: sequence(:clauses)) { Query.new(clauses) }
  end

  # Represents an operator
  class Operator
    def self.symbol(str)
      case str
      when '+'
        :must
      when '-'
        :must_not
      when nil
        :should
      else
        raise "Unknown operator: #{str}"
      end
    end
  end

  # Represents a term clause
  class TermClause
    attr_accessor :operator, :term

    def initialize(operator, term)
      self.operator = Operator.symbol(operator)
      self.term = term
    end
  end

  # Represents a phrase clause
  class PhraseClause
    attr_accessor :operator, :phrase

    def initialize(operator, phrase)
      self.operator = Operator.symbol(operator)
      self.phrase = phrase
    end
  end

  ## Query object
  class Query
    attr_accessor :should_clauses, :must_not_clauses, :must_clauses

    def initialize(clauses)
      grouped = clauses.chunk(&:operator).to_h
      self.should_clauses = grouped.fetch(:should, [])
      self.must_not_clauses = grouped.fetch(:must_not, [])
      self.must_clauses = grouped.fetch(:must, [])
    end

    def to_elasticsearch
      CLAUSE_TYPES.each_with_object({}) do |type, query|
        clauses = instance_variable_get("@#{type}_clauses")
        query[type] = clauses.map { |clause| clause_to_query(clause) } if clauses&.any?
      end
    end

    def clause_to_query(clause)
      case clause
      when TermClause
        match(clause.term)
      when PhraseClause
        match_phrase(clause.phrase)
      else
        raise "Unknown clause type: #{clause}"
      end
    end

    def match(term)
      term
    end

    def match_phrase(phrase)
      phrase
    end
  end
end
