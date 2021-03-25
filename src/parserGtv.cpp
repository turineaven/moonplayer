/* Copyright 2013-2020 Aven <turineaven@github>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

#include "parserGtv.h"
#include "accessManager.h"
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTextStream>
#include "dialogs.h"

ParserGTV ParserGTV::s_instance;

bool ParserGTV::isSupported(const QUrl& url)
{
    return (url.scheme() == QLatin1String("http") || url.scheme() == QLatin1String("https")) &&
        url.host() == QLatin1String("gtv.org") &&
        (url.path().startsWith(QLatin1String("/video/id=")) || url.path().startsWith(QLatin1String("/getter/")));
}

void ParserGTV::runParser(const QUrl& url)
{
    bool ok;
    QString id = url.fileName();
    if (id.startsWith(QLatin1String("id=")))
        id.remove(0, 3);
    long value = id.leftRef(8).toLong(&ok, 16);
    if (!ok)
    {
        showErrorDialog(QStringLiteral("Unrecognized gtv.org URL"));
        return;
    }
    result.title = id;

    /* certain range:
    0x6057baed <= t : group7              // video/id=6057baeda26ac57138e09ffb
    0x600bc7b8 <= t <= 6057b28a : group6  // video/id=6057b28aa26ac57138e09a0a
                                          // video/id=600bc7b887fabe2daf3fd61f
    t <= 0x600bbe5e : group5              // getter/600bbe5e87fabe2daf3fd0e6  */
    char gid;
    if (value < 0x600bc000)
        gid = '5';
    else if (value < 0x6057b600)
        gid = '6';
    else
        gid = '7';
    QDateTime time = QDateTime::fromSecsSinceEpoch(value, Qt::UTC);
    QString m3u8 = QStringLiteral("https://filegroup.gtv.org/group") +
                   QLatin1Char(gid) +
                   QStringLiteral("/vm3u8/") +
                   time.toString(QStringLiteral("yyyyMMdd/hh/mm/")) + id +
                   QStringLiteral("/hls.m3u8");

    QNetworkRequest request(m3u8);
    QNetworkReply *reply = NetworkAccessManager::instance()->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(replyFinished()));
}

void ParserGTV::replyFinished(void)
{
    QRegExp resRx(QStringLiteral("RESOLUTION=([0-9x]{3,})"));
    QRegExp bwRx(QStringLiteral("BANDWIDTH=([0-9]{1,})"));
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(QObject::sender());
    QUrl base = reply->url().adjusted(QUrl::RemoveFilename);
    QTextStream body(reply);

    Stream stream;
    stream.container = QLatin1String("m3u8");
    stream.referer = QLatin1String("https://gtv.org/");
    stream.seekable = true;
    stream.is_dash = false;

    QString error;
    if (reply->error())
    {   // network error
        error = reply->errorString();
        goto error;
    }

    if (body.readLine() != QLatin1String("#EXTM3U"))
    {   // unexpected playlist format
        error = QLatin1String("Not a .m3u8 playlist");
        goto error;
    }

    for (QString line; !(line = body.readLine().trimmed()).isNull();)
    {
        if (line.startsWith(QLatin1String("#EXT-X-STREAM-INF:")) &&
            bwRx.indexIn(line) >= 0)
        {   // generate label : resolution and bandwidth
            float bw = bwRx.cap(1).toFloat()/1000;
            QString type;
            if (resRx.indexIn(line) >= 0)
               type = resRx.cap(1);
            else
               type = QLatin1String("Unknown");
            type += QLatin1String("  (");

            if (bw < 1000)
                type += QString::number(bw, 'f', 0) + QLatin1String(" K");
            else
                type += QString::number(bw / 1000, 'f', 2) + QLatin1String(" M");
            type += QLatin1String("b/s)");
            result.stream_types += type;
        }
        else if (!line.startsWith(QLatin1Char('#')) &&
                 result.stream_types.count() == result.streams.count() + 1)
        {   // media playlist URL
            stream.urls = QList<QUrl>({base.resolved(line)});
            result.streams += stream;
        }
    }

    if (result.streams.size() == result.stream_types.count()) {
        if (!result.streams.size())
        {   // not a master playlist, should be a media playlist
            stream.urls += reply->url();
            result.streams += stream;
        }
        finishParsing();
    }
    else
    {
        error = QLatin1String("Malformed .m3u8 playlist");
    }

error:
    reply->deleteLater();
    if (!error.isEmpty())
        showErrorDialog(error);
}
