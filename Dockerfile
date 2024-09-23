FROM python:3.9

WORKDIR /app

COPY app.py /app/


RUN pip install flask prometheus_flask_exporter

EXPOSE 5000

CMD ["python", "app.py"]
