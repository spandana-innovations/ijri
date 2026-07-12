import sanitizeHtml from "sanitize-html";

// Sanitises stored article HTML before rendering. Rich enough for scholarly
// articles (headings, figures, tables, emphasis) but strips anything scriptable.
export function sanitize(dirty: string): string {
  return sanitizeHtml(dirty, {
    allowedTags: ["p", "h2", "h3", "h4", "ul", "ol", "li", "strong", "em", "b", "i", "u", "blockquote", "figure", "figcaption", "img", "a", "br", "hr", "sup", "sub", "table", "thead", "tbody", "tr", "td", "th", "code", "pre", "div", "span"],
    allowedAttributes: { a: ["href", "name", "target", "rel"], img: ["src", "alt", "width", "height"], "*": ["style"] },
    allowedSchemes: ["https", "data"],
  });
}
