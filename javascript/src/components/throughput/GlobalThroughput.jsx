import React from 'react';
import Reflux from 'reflux';
import numeral from 'numeral';

import GlobalThroughputStore from 'stores/metrics/GlobalThroughputStore';

import MetricsActions from 'actions/metrics/MetricsActions';

import { Spinner } from 'components/common';

const GlobalThroughput = React.createClass({
  mixins: [Reflux.connect(GlobalThroughputStore)],
  componentDidMount() {
    setInterval(MetricsActions.list, 2000);
  },
  render() {
    if (!this.state.throughput) {
      return <Spinner />;
    }
    return (
      <span>
        In <strong className="total-throughput">{numeral(this.state.throughput.input).format('0,0')}</strong>{' '}
        / Out <strong className="total-throughput">{numeral(this.state.throughput.output).format('0,0')}</strong> msg/s
      </span>
    );
  },
});

export default GlobalThroughput;
