function SDFgraph = SDFgraph_read(infile)
addpath('ultilities/');
DOMnode = xmlread(infile);
theStruct = xml2struct(DOMnode);
clear DOMnode

%SDFgraph filename
[filepath,name,ext] = fileparts(infile);
SDFgraph.filename   = name;
SDFgraph.filepath   = filepath;
clear filepath name ext infile

%SDFgraph constrain
invthroughput = theStruct.sdf3.applicationGraph.sdfProperties.graphProperties.timeConstraints.invthroughput.Text;
SDFgraph.timeConstraints = str2double(invthroughput);
clear invthroughput

%SDFgraph actor
allActors= [];
map_name2idx = containers.Map;
map_port2rate= containers.Map;
nActor   = length(theStruct.sdf3.applicationGraph.sdf.actor);
nChannel = length(theStruct.sdf3.applicationGraph.sdf.channel);
for idx  = 1:nActor
    if nActor == 1
        actor       = theStruct.sdf3.applicationGraph.sdf.actor;
    else
        actor       = theStruct.sdf3.applicationGraph.sdf.actor{idx};
    end
    mActor.name = actor.Attributes.name;
    map_name2idx(mActor.name) = idx;
    nport = length(actor.port);
    for jdx = 1:nport
       if nport == 1
           port = actor.port.Attributes;
       else
           port = actor.port{jdx}.Attributes;
       end
       name = [mActor.name '_' port.name];
       map_port2rate(name) = str2double(port.rate);
    end
    
    if nActor == 1
        actor       = theStruct.sdf3.applicationGraph.sdfProperties.actorProperties;
    else
        actor       = theStruct.sdf3.applicationGraph.sdfProperties.actorProperties{idx};
    end
    if (~strcmp(mActor.name, actor.Attributes.actor))
        error('actor name is different!');
    end
    mActor.execTime = str2double(actor.processor.executionTime.Attributes.time);
    allActors = [allActors mActor];
end
SDFgraph.actors = allActors;
clear actor mActor allActors port nport name

%SDFgraph channel
allChannels = cell(nActor,nActor);
for idx  = 1:nChannel
    if nChannel == 1
        channel = theStruct.sdf3.applicationGraph.sdf.channel.Attributes;
    else
        channel = theStruct.sdf3.applicationGraph.sdf.channel{idx}.Attributes;
    end
    mChannel.name = channel.name;
    name = [channel.srcActor '_' channel.srcPort];
    mChannel.rate_in = map_port2rate(name);
    name = [channel.dstActor '_' channel.dstPort];
    mChannel.rate_out= map_port2rate(name);
    if isfield(channel, 'initialTokens')
        mChannel.initialTokens = str2num(channel.initialTokens);
    else
        mChannel.initialTokens = 0;
    end
    allChannels{map_name2idx(channel.srcActor),map_name2idx(channel.dstActor)} = mChannel;
end
SDFgraph.channels = allChannels;
SDFgraph.map_name2idx = map_name2idx;
clear name channel mChannel allChannels idx jdx
end