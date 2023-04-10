FROM rabbitmq:3.7.7

ADD rabbitmq.config /etc/rabbitmq/
ADD definitions.json /etc/rabbitmq/
ADD enabled_plugins /etc/rabbitmq/enabled_plugins
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.config /etc/rabbitmq/definitions.json
CMD ["rabbitmq-server"]