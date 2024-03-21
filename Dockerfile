FROM registry.gitlab.com/pages/hugo/hugo_extended:0.124.1
WORKDIR /site
CMD [ "serve", "-D", "--bind", "0.0.0.0", "--config", "/site/hugo.yaml" ]
ENTRYPOINT [ "hugo" ]
