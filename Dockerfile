FROM ruby:2.2-onbuild
CMD ["rackup", "-o", "0.0.0.0"]
EXPOSE 9292
