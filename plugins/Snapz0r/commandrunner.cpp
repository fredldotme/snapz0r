#include "commandrunner.h"

#include <QDebug>
#include <QThread>
#include <limits>

CommandRunner::CommandRunner(QObject *parent) :
    QObject(parent),
    m_process(newProcess())
{
}

QProcess* CommandRunner::newProcess()
{
    auto process = new QProcess();
    process->moveToThread(QThread::currentThread());

    connect(process, &QProcess::stateChanged, this, [=](QProcess::ProcessState state) {
        if (state == QProcess::NotRunning) {
            qDebug() << "Command stopped";
            if (process != this->m_process)
                process->deleteLater();
        }
    }, Qt::DirectConnection);
    connect(process, &QProcess::readyReadStandardError,
            this, [=]() {
        const QByteArray stdErrContent = process->readAllStandardError();
        qDebug() << stdErrContent;
        if (stdErrContent.contains("userpasswd")) {
            emit passwordRequested();
        }
    }, Qt::DirectConnection);
    return process;
}

int CommandRunner::shell(const QStringList &command, const bool waitForCompletion, QByteArray* output)
{
    QStringList cmd = QStringList{"-c", command.join(" ")};

    this->m_process->start("bash", cmd, QProcess::ReadWrite);
    this->m_process->waitForStarted();

    if (waitForCompletion) {
        this->m_process->waitForFinished(std::numeric_limits<int>::max());
        if (output) {
            *output = this->m_process->readAllStandardOutput();
        }
        qDebug() << this->m_process->exitCode();
        const int ret = this->m_process->exitCode();
        return ret;
    }
    return -1;
}

int CommandRunner::sudo(const QStringList &command, const bool waitForCompletion, const bool separateProcess, QByteArray* output)
{
    QStringList cmd = QStringList{"-S", "-p", "userpasswd"} + command;
    qDebug() << "running" << cmd.join(" ");

    auto process = separateProcess ? newProcess() : m_process;

    process->start("sudo", cmd, QProcess::ReadWrite);
    process->waitForStarted();

    if (waitForCompletion) {
        process->waitForFinished(std::numeric_limits<int>::max());
        if (output) {
            *output = process->readAllStandardOutput();
        }
        qDebug() << process->exitCode();
        const int ret = process->exitCode();
        return ret;
    }
    return -1;
}

bool CommandRunner::sudo(const QStringList &command)
{
    return sudo(command, true, false, 	nullptr);
}

QByteArray CommandRunner::readFile(const QString &absolutePath)
{
    sudo(QStringList{"cat" , absolutePath});
    this->m_process->waitForFinished();
    const QByteArray value = this->m_process->readAllStandardOutput();
    qDebug() << absolutePath << "=" << value;
    return value;
}

bool CommandRunner::writeFile(const QString &absolutePath, const QByteArray &value)
{
    const QStringList writeCommand {
        QStringLiteral("/bin/sh"), QStringLiteral("-c"),
        QStringLiteral("echo '%1' | tee %2").arg(value, absolutePath)
    };
    sudo(writeCommand);
    return (this->m_process->exitCode() == 0);
}

bool CommandRunner::rm(const QString& path)
{
    const QStringList writeCommand {
        QStringLiteral("/bin/sh"), QStringLiteral("-c"),
        QStringLiteral("/bin/rm '%1'").arg(path)
    };
    sudo(writeCommand);
    return (this->m_process->exitCode() == 0);
}

void CommandRunner::providePassword(const QString& password)
{
    this->m_process->write(password.toUtf8());
    this->m_process->write("\n");
}

bool CommandRunner::validatePassword()
{
    const QStringList idCommand {
        QStringLiteral("id"), QStringLiteral("-u")
    };
    sudo(idCommand);
    this->m_process->waitForFinished();
    const QByteArray output = this->m_process->readAllStandardOutput();
    return (output.trimmed() == "0");
}

void CommandRunner::cancel()
{
    m_process->kill();
    m_process->waitForFinished();
}
