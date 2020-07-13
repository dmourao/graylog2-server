// @flow strict
import * as React from 'react';

import UserOverview from 'logic/users/UserOverview';

import ActionsCell from './ActionsCell';
import LoggedInCell from './LoggedInCell';
import RolesCell from './RolesCell';

type Props = {
  user: UserOverview,
  isActive: boolean,
};

const UsersOverviewItem = ({
  user: {
    clientAddress,
    email,
    fullName,
    lastActivity,
    sessionActive,
    username,
    readOnly,
    roles,
  },
  isActive,
}: Props) => {
  return (
    <tr key={username} className={isActive ? 'active' : ''}>
      <LoggedInCell lastActivity={lastActivity}
                    clientAddress={clientAddress}
                    sessionActive={sessionActive} />
      <td className="limited">{fullName}</td>
      <td className="limited">{username}</td>
      <td className="limited">{email}</td>
      <td className="limited">{clientAddress}</td>
      <RolesCell roles={roles} />
      <ActionsCell username={username} readOnly={readOnly} />
    </tr>
  );
};

export default UsersOverviewItem;