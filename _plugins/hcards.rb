require "cgi"

module Jekyll
  module Tags
    module HCardAttrs
      ATTR_RE = /(\w+)\s*=\s*"([^"]*)"/.freeze

      def parse_attrs(markup)
        markup.scan(ATTR_RE).to_h
      end
    end

    class HCardsTag < Liquid::Block
      include HCardAttrs

      def initialize(tag_name, markup, tokens)
        super
        @attrs = parse_attrs(markup)
      end

      def render(context)
        title = @attrs["title"]
        body = super(context)
        label = title && !title.empty? ? "<div class=\"hcards__title\">#{CGI.escapeHTML(title)}</div>" : ""

        <<~HTML
          <section class="hcards" aria-label="#{CGI.escapeHTML(title || "Card deck")}">
            #{label}
            <div class="hcards__rail" tabindex="0">
              #{body}
            </div>
          </section>
        HTML
      end
    end

    class HCardTag < Liquid::Block
      include HCardAttrs

      def initialize(tag_name, markup, tokens)
        super
        @attrs = parse_attrs(markup)
      end

      def render(context)
        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        id_attr = @attrs["id"] && !@attrs["id"].empty? ? " id=\"#{CGI.escapeHTML(@attrs["id"])}\"" : ""
        title = @attrs["title"]
        heading = title && !title.empty? ? "<h4 class=\"hcard__title\">#{CGI.escapeHTML(title)}</h4>" : ""
        body = converter.convert(super(context))

        <<~HTML
          <article#{id_attr} class="hcard">
            #{heading}
            <div class="hcard__body">
              #{body}
            </div>
          </article>
        HTML
      end
    end
  end
end

Liquid::Template.register_tag("hcards", Jekyll::Tags::HCardsTag)
Liquid::Template.register_tag("hcard", Jekyll::Tags::HCardTag)
