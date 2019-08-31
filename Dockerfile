FROM node:10

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wkhtmltopdf \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*


# https://github.com/hacksalot/HackMyResume
#   https://www.npmjs.com/search?q=jsonresume-theme
#   https://www.npmjs.com/search?q=fresh-theme
#   https://github.com/fresh-standard/fresh-themes

# jsonresume-theme-elegant \
# jsonresume-theme-paper \
# jsonresume-theme-kendall \
# jsonresume-theme-modern \
# jsonresume-theme-classy \
# jsonresume-theme-class \
# jsonresume-theme-short \
# jsonresume-theme-slick \
# jsonresume-theme-kwan \
# jsonresume-theme-onepage \
# jsonresume-theme-spartan \
# jsonresume-theme-stackoverflow

# Install hackmyresume and jsonresume themes packages
RUN npm install -g \
    hackmyresume@1.9.0-beta

ENTRYPOINT [ "hackmyresume" ]
